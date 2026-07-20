{inputs, ...}: {
  perSystem = {pkgs, ...}: {
    packages.omp = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.omp;
  };
}
