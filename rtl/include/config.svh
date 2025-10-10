`ifndef SIM
  // Most synthesis tools predefine SYNTHESIS.
  // In sim, SYNTHESIS is *not* defined, so enable SIM by default.
  
  `ifndef SYNTHESIS
    `define SIM
  `endif
`endif