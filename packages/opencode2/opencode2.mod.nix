{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    packages.opencode2 = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode2;
  };
}
