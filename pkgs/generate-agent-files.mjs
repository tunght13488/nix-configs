/**
 * OpenSpec Agent Files Generator
 *
 * Build script that imports adapters and template modules from the OpenSpec
 * source tree and generates .pi/ and .opencode/ agent integration files
 * (skills, prompts, commands) at build time.
 *
 * Run through esbuild: esbuild this-file --bundle --platform=node --format=esm
 *
 * Consumed by pkgs/openspec-agent-files.nix to replace checked-in generated files.
 */

import { mkdirSync, writeFileSync } from 'node:fs';
import { dirname } from 'node:path';
import {
  getSkillTemplates,
  generateSkillContent,
  getCommandContents,
} from './src/core/shared/skill-generation.ts';
import { piAdapter } from './src/core/command-generation/adapters/pi.ts';
import { opencodeAdapter } from './src/core/command-generation/adapters/opencode.ts';
import { generateCommands } from './src/core/command-generation/generator.ts';
import { getTransformerForTool } from './src/utils/command-references.ts';
import { getInvocationForAdapter } from './src/core/command-generation/invocation.ts';

const VERSION = process.env.OPENSPEC_VERSION || '0.0.0';

// ---------------------------------------------------------------------------
// Helper
// ---------------------------------------------------------------------------

function writeFile(path, content) {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, content, 'utf-8');
}

// ---------------------------------------------------------------------------
// Skills (SKILL.md) for Pi and OpenCode
// ---------------------------------------------------------------------------

// Pi and OpenCode both name commands by filename (flat invocation, `/opsx-<id>`),
// so their skills get the same `/opsx-` spelling (v1.6+ API; replaces the old
// `transformToHyphenCommands` helper).
const skillRefTransformer = getTransformerForTool(
  'pi',
  'both',
  'adapter-backed',
  getInvocationForAdapter(piAdapter)
);

for (const { template, dirName } of getSkillTemplates()) {
  const md = generateSkillContent(template, VERSION, skillRefTransformer);

  // Pi
  writeFile(`.pi/skills/${dirName}/SKILL.md`, md);

  // OpenCode
  writeFile(`.opencode/skills/${dirName}/SKILL.md`, md);
}

// ---------------------------------------------------------------------------
// Commands (slash / prompt templates) for Pi
// ---------------------------------------------------------------------------

for (const cmd of generateCommands(getCommandContents(), piAdapter)) {
  writeFile(cmd.path, cmd.fileContent);
}

// ---------------------------------------------------------------------------
// Commands for OpenCode
// ---------------------------------------------------------------------------

for (const cmd of generateCommands(getCommandContents(), opencodeAdapter)) {
  writeFile(cmd.path, cmd.fileContent);
}
