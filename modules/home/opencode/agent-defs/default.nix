{}:
let
  common = import ./common.nix {};
in
{
  build = import ./build.nix { inherit common; };
  project_lead = import ./project_lead.nix { inherit common; };
  architect = import ./architect.nix { inherit common; };
  developer = import ./developer.nix { inherit common; };
  devops_engineer = import ./devops_engineer.nix { inherit common; };
  product_manager = import ./product_manager.nix { inherit common; };
  qa_engineer = import ./qa_engineer.nix { inherit common; };
  security_engineer = import ./security_engineer.nix { inherit common; };
  technical_writer = import ./technical_writer.nix { inherit common; };
  ux_designer = import ./ux_designer.nix { inherit common; };
}