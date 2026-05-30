{ config, inputs, ... }:

{
  perSystem =
    { system, ... }:
    {
      checks =
        if system == "x86_64-linux" then
          {
            cinderace-toplevel = inputs.self.nixosConfigurations.cinderace.config.system.build.toplevel;
          }
        else
          { };
    };
}
