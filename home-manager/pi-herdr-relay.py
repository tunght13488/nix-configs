#!/usr/bin/env python3
"""Filtered herdr API relay for pi-box sandboxes.

Consumers: home-manager/pi-sandbox.nix deploys this to ~/.pi/sandbox/, and the
`pi-box` wrapper starts it once per run inside a herdr pane. The sandbox is
given only this socket; the real herdr API socket (which can read and drive
every pane) is never mounted.

The relay accepts one JSON line per connection and forwards it to herdr only
when it is one of the two agent state report methods. The pane id is forced to
the host pane's, and reported session paths are mapped from the container view
(/root/.pi/agent/...) to the host state directory so herdr stores a path it can
use for restart-resume. Everything else is dropped without reaching herdr.

Self-check: `pi-herdr-relay.py --self-test` exercises the filter and the path
rewrite without opening any socket.
"""

import argparse
import json
import os
import socket
import sys
import threading

# The only methods the sandbox may send. Both are agent state reports.
ALLOWED_METHODS = frozenset({"pane.report_agent", "pane.report_agent_session"})

# Where the shared Pi state directory is mounted inside the sandbox.
CONTAINER_STATE_DIR = "/root/.pi/agent"

# One report line is a few hundred bytes; refuse anything unreasonable.
MAX_LINE_BYTES = 64 * 1024


def rewrite_session_path(value, host_state_dir):
    """Map a container session path to its host path; leave anything else alone."""
    if not isinstance(value, str):
        return value
    prefix = CONTAINER_STATE_DIR + "/"
    if not value.startswith(prefix):
        return value
    return os.path.join(host_state_dir, value[len(prefix):])


def sanitize_request(raw, pane_id, host_state_dir):
    """Return the line to forward, or None when the request must be dropped."""
    try:
        request = json.loads(raw)
    except (UnicodeDecodeError, ValueError):
        return None
    if not isinstance(request, dict):
        return None
    if request.get("method") not in ALLOWED_METHODS:
        return None

    params = request.get("params")
    if not isinstance(params, dict):
        params = {}
    params["pane_id"] = pane_id
    if "agent_session_path" in params:
        params["agent_session_path"] = rewrite_session_path(
            params["agent_session_path"], host_state_dir
        )
    request["params"] = params
    return (json.dumps(request, separators=(",", ":")) + "\n").encode()


def read_line(connection):
    """Read one newline-terminated line, bounded; return bytes or None."""
    buffer = bytearray()
    while len(buffer) < MAX_LINE_BYTES:
        try:
            chunk = connection.recv(4096)
        except OSError:
            return None
        if not chunk:
            break
        buffer.extend(chunk)
        if b"\n" in chunk:
            break
    if not buffer:
        return None
    newline = buffer.find(b"\n")
    return bytes(buffer if newline == -1 else buffer[:newline])


def forward(api_socket_path, payload):
    """Send one line to herdr's API socket and return its response line."""
    client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    client.settimeout(5.0)
    try:
        client.connect(api_socket_path)
        client.sendall(payload)
        return read_line(client)
    except OSError:
        return None
    finally:
        client.close()


def handle_connection(connection, api_socket_path, pane_id, host_state_dir):
    with connection:
        raw = read_line(connection)
        if raw is None:
            return
        forwarded = sanitize_request(raw, pane_id, host_state_dir)
        if forwarded is None:
            # Dropped: close without forwarding, so the sender sees no delivery.
            return
        response = forward(api_socket_path, forwarded)
        if response is None:
            return
        try:
            connection.sendall(response + b"\n")
        except OSError:
            pass


def serve(socket_path, api_socket_path, pane_id, host_state_dir):
    os.umask(0o077)
    try:
        os.unlink(socket_path)
    except FileNotFoundError:
        pass
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(socket_path)
    server.listen(16)
    try:
        while True:
            connection, _ = server.accept()
            threading.Thread(
                target=handle_connection,
                args=(connection, api_socket_path, pane_id, host_state_dir),
                daemon=True,
            ).start()
    finally:
        server.close()
        try:
            os.unlink(socket_path)
        except FileNotFoundError:
            pass


def run_self_test():
    host_state_dir = "/home/test/.pi/agent"
    pane_id = "w1:p2"

    allowed = sanitize_request(
        b'{"id":"a","method":"pane.report_agent","params":{"pane_id":"p1","state":"working"}}',
        pane_id,
        host_state_dir,
    )
    assert allowed is not None, "report_agent must be forwarded"
    forwarded = json.loads(allowed)
    assert forwarded["params"]["pane_id"] == pane_id, "pane id must be forced"

    session = sanitize_request(
        b'{"id":"b","method":"pane.report_agent_session","params":{"pane_id":"p1",'
        b'"agent_session_path":"/root/.pi/agent/sessions/x/y.jsonl"}}',
        pane_id,
        host_state_dir,
    )
    assert session is not None, "report_agent_session must be forwarded"
    assert (
        json.loads(session)["params"]["agent_session_path"]
        == "/home/test/.pi/agent/sessions/x/y.jsonl"
    ), "session path must be rewritten to the host view"

    for dropped in (
        b'{"id":"c","method":"pane.read","params":{}}',
        b'{"id":"d","method":"pane.spawn","params":{}}',
        b'{"id":"e","method":"agent.prompt","params":{}}',
        b"not json",
        b'["array"]',
    ):
        assert sanitize_request(dropped, pane_id, host_state_dir) is None, (
            "must drop: " + dropped.decode(errors="replace")
        )

    assert (
        rewrite_session_path("/root/.pi/agent-sessions/x", host_state_dir)
        == "/root/.pi/agent-sessions/x"
    ), "only the exact state directory prefix may be rewritten"

    print("pi-herdr-relay: self-test passed")
    return 0


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--socket", help="relay socket path (created with umask 077)")
    parser.add_argument("--api-socket", help="herdr API socket path")
    parser.add_argument("--pane-id", help="host herdr pane id to force on reports")
    parser.add_argument("--host-state-dir", help="host Pi state directory")
    parser.add_argument("--self-test", action="store_true", help="run the built-in self-check")
    args = parser.parse_args(argv)

    if args.self_test:
        return run_self_test()

    missing = [
        name
        for name, value in (
            ("--socket", args.socket),
            ("--api-socket", args.api_socket),
            ("--pane-id", args.pane_id),
            ("--host-state-dir", args.host_state_dir),
        )
        if not value
    ]
    if missing:
        parser.error("missing required options: " + ", ".join(missing))

    try:
        serve(args.socket, args.api_socket, args.pane_id, args.host_state_dir)
    except KeyboardInterrupt:
        return 0
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
