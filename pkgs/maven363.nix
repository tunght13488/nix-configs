{ pkgs }:
(pkgs.maven.override { jdk_headless = pkgs.jdk8_headless; }).overrideAttrs {
  version = "3.6.3";
  src = pkgs.fetchurl {
    url = "https://repo1.maven.org/maven2/org/apache/maven/apache-maven/3.6.3/apache-maven-3.6.3-bin.tar.gz";
    hash = "sha256-Jq2R11GzqaUwh676dD9OFqF3QdORWyGc90ESv4ekOMU=";
  };
}
