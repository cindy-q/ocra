global fclk
global f_aresetn
global f_reset
global pl_param_dict

# Create xlslice
# Trigger slice on Bit 1 (RX pulse)
cell xilinx.com:ip:xlslice:1.0 slice_0 {
  DIN_WIDTH 8 DIN_FROM 1 DIN_TO 1 DOUT_WIDTH 1
}

# Create xlslice
cell xilinx.com:ip:xlslice:1.0 rate_slice {
  DIN_WIDTH 32 DIN_FROM 15 DIN_TO 0 DOUT_WIDTH 16
}

# Create xlconstant
cell xilinx.com:ip:xlconstant:1.1 const_0

# Create axis_clock_converter
cell xilinx.com:ip:axis_clock_converter:1.1 fifo_0 {
  TDATA_NUM_BYTES.VALUE_SRC USER
  TDATA_NUM_BYTES 4
} {
  m_axis_aclk $fclk
  m_axis_aresetn $f_aresetn
}

if { [dict get $pl_param_dict modulated] == "TRUE"} {
    # Create axis_lfsr
    cell pavel-demin:user:axis_lfsr:1.0 lfsr_0 {} {
      aclk $fclk
      aresetn $f_aresetn
    }
    # Create cmpy
    cell xilinx.com:ip:cmpy:6.0 mult_0 {
      FLOWCONTROL Blocking
      APORTWIDTH.VALUE_SRC USER
      BPORTWIDTH.VALUE_SRC USER
      APORTWIDTH 16
      BPORTWIDTH 24
      ROUNDMODE Random_Rounding
      OUTPUTWIDTH 26
    } {
      S_AXIS_A fifo_0/M_AXIS
      S_AXIS_CTRL lfsr_0/M_AXIS
      aclk $fclk
    }
    # Create axis_broadcaster
    cell xilinx.com:ip:axis_broadcaster:1.1 bcast_0 {
      S_TDATA_NUM_BYTES.VALUE_SRC USER
      M_TDATA_NUM_BYTES.VALUE_SRC USER
      S_TDATA_NUM_BYTES 8
      M_TDATA_NUM_BYTES 3
      M00_TDATA_REMAP {tdata[23:0]}
      M01_TDATA_REMAP {tdata[55:32]}
    } {
      S_AXIS mult_0/M_AXIS_DOUT
      aclk $fclk
      aresetn $f_aresetn
    }
} else {
    # Create axis_broadcaster
    cell xilinx.com:ip:axis_broadcaster:1.1 bcast_0 {
      S_TDATA_NUM_BYTES.VALUE_SRC USER
      M_TDATA_NUM_BYTES.VALUE_SRC USER
      S_TDATA_NUM_BYTES 4
      M_TDATA_NUM_BYTES 3
      M00_TDATA_REMAP {tdata[15:0],  8'b0}
      M01_TDATA_REMAP {tdata[31:16], 8'b0}
    } {
      S_AXIS fifo_0/M_AXIS
      aclk $fclk
      aresetn $f_aresetn
    }
}

# Create axis_variable
cell pavel-demin:user:axis_variable:1.0 rate_0 {
  AXIS_TDATA_WIDTH 16
} {
  cfg_data rate_slice/Dout
  aclk $fclk
  aresetn $f_aresetn
}

# Create axis_variable
cell pavel-demin:user:axis_variable:1.0 rate_1 {
  AXIS_TDATA_WIDTH 16
} {
  cfg_data rate_slice/Dout
  aclk $fclk
  aresetn $f_aresetn
}

# Create cic_compiler
cell xilinx.com:ip:cic_compiler:4.0 cic_0 {
  INPUT_DATA_WIDTH.VALUE_SRC USER
  FILTER_TYPE Decimation
  NUMBER_OF_STAGES 6
  SAMPLE_RATE_CHANGES Programmable
  MINIMUM_RATE 25
  MAXIMUM_RATE 8192
  FIXED_OR_INITIAL_RATE 625
  INPUT_SAMPLE_FREQUENCY 125
  CLOCK_FREQUENCY 125
  INPUT_DATA_WIDTH 24
  QUANTIZATION Truncation
  OUTPUT_DATA_WIDTH 24
  USE_XTREME_DSP_SLICE false
  HAS_DOUT_TREADY true
  HAS_ARESETN true
} {
  S_AXIS_DATA bcast_0/M00_AXIS
  S_AXIS_CONFIG rate_0/M_AXIS
  aclk $fclk
  aresetn $f_aresetn
}

# Create cic_compiler
cell xilinx.com:ip:cic_compiler:4.0 cic_1 {
  INPUT_DATA_WIDTH.VALUE_SRC USER
  FILTER_TYPE Decimation
  NUMBER_OF_STAGES 6
  SAMPLE_RATE_CHANGES Programmable
  MINIMUM_RATE 25
  MAXIMUM_RATE 8192
  FIXED_OR_INITIAL_RATE 625
  INPUT_SAMPLE_FREQUENCY 125
  CLOCK_FREQUENCY 125
  INPUT_DATA_WIDTH 24
  QUANTIZATION Truncation
  OUTPUT_DATA_WIDTH 24
  USE_XTREME_DSP_SLICE false
  HAS_DOUT_TREADY true
  HAS_ARESETN true
} {
  S_AXIS_DATA bcast_0/M01_AXIS
  S_AXIS_CONFIG rate_1/M_AXIS
  aclk $fclk
  aresetn $f_aresetn
}

# Create axis_combiner
cell  xilinx.com:ip:axis_combiner:1.1 comb_0 {
  TDATA_NUM_BYTES.VALUE_SRC USER
  TDATA_NUM_BYTES 3
} {
  S00_AXIS cic_0/M_AXIS_DATA
  S01_AXIS cic_1/M_AXIS_DATA
  aclk $fclk
  aresetn $f_aresetn
}

# Create axis_dwidth_converter
cell xilinx.com:ip:axis_dwidth_converter:1.1 conv_0 {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 6
  M_TDATA_NUM_BYTES 3
} {
  S_AXIS comb_0/M_AXIS
  aclk $fclk
  aresetn $f_aresetn
}

# Create fir_compiler
cell xilinx.com:ip:fir_compiler:7.2 fir_0 {
  DATA_WIDTH.VALUE_SRC USER
  DATA_WIDTH 24
  COEFFICIENTVECTOR {-1.6472113056e-08, -4.7275060561e-08, -7.7431048180e-10, 3.0903860136e-08, 1.8580664775e-08, 3.2714281320e-08, -6.2515870285e-09, -1.5212421546e-07, -8.3024102014e-08, 3.1421287283e-07, 3.0541061907e-07, -4.7367916408e-07, -7.1290982678e-07, 5.4673392936e-07, 1.3334649132e-06, -4.1364098644e-07, -2.1485949525e-06, -6.7829977410e-08, 3.0726845332e-06, 1.0362499293e-06, -3.9407657887e-06, -2.5897362011e-06, 4.5112332508e-06, 4.7436885121e-06, -4.4887077258e-06, -7.3916945269e-06, 3.5688710327e-06, 1.0280353312e-05, -1.5024372933e-06, -1.3009229990e-05, -1.8303781261e-06, 1.5064716289e-05, 6.3487776401e-06, -1.5891625499e-05, -1.1721675486e-05, 1.4997961053e-05, 1.7356048979e-05, -1.2084227227e-05, -2.2446408027e-05, 7.1644345011e-06, 2.6079710827e-05, -6.6454989299e-07, -2.7404912150e-05, -6.5427500664e-06, 2.5842003924e-05, 1.3190154000e-05, -2.1299612136e-05, -1.7771633363e-05, 1.4356250995e-05, 1.8800552428e-05, -6.3558764252e-06, -1.5147259248e-05, -6.2897066014e-07, 6.4094323907e-06, 3.9982503227e-06, 6.7506282624e-06, -9.9796014867e-07, -2.2380212454e-05, -1.0759547197e-05, 3.7195306717e-05, 3.2677486281e-05, -4.6811898990e-05, -6.4599447382e-05, 4.6210324771e-05, 1.0431120674e-04, -3.0503826568e-05, -1.4732577300e-04, -4.1258453650e-06, 1.8701663321e-04, 5.9427713818e-05, -2.1517847459e-04, -1.3418896425e-04, 2.2301952102e-04, 2.2363993628e-04, -2.0251435162e-04, -3.1934040767e-04, 1.4796009669e-04, 4.0968443718e-04, -5.7507336159e-05, -4.8108463752e-04, -6.5614839363e-05, 5.1978739429e-04, 2.1246715982e-04, -5.1416395507e-04, -3.6866549936e-04, 4.5707019142e-04, 5.1550012249e-04, -3.4818706949e-04, -6.3230445935e-04, 1.9550609650e-04, 6.9955714665e-04, -1.5827253275e-05, -7.0258143521e-04, -1.6617637952e-04, 6.3529569901e-04, 3.2048789072e-04, -5.0340105072e-04, -4.1582530241e-04, 3.2634180427e-04, 4.2496083963e-04, -1.3743221406e-04, -3.3071450507e-04, -1.8305167738e-05, 1.3182485134e-04, 8.8784066371e-05, 1.5224742206e-04, -2.1850002011e-05, -4.7861967162e-04, -2.2609003083e-04, 7.8079557647e-04, 6.7984527906e-04, -9.7283144780e-04, -1.3363233256e-03, 9.5648007150e-04, 2.1563565688e-03, -6.3230621305e-04, -3.0596594938e-03, -8.6386881070e-05, 3.9239359768e-03, 1.2579439516e-03, -4.5890114465e-03, -2.8966063910e-03, 4.8663498835e-03, 4.9583669373e-03, -4.5537073976e-03, -7.3301527521e-03, 3.4540124085e-03, 9.8237515984e-03, -1.3969575800e-03, -1.2175276174e-02, -1.7386657056e-03, 1.4049779174e-02, 6.0029171665e-03, -1.5052324818e-02, -1.1359609346e-02, 1.4735662483e-02, 1.7670980642e-02, -1.2608162870e-02, -2.4690698016e-02, 8.1251717279e-03, 3.2057724080e-02, -6.4695302151e-04, -3.9282618887e-02, -1.0679394699e-02, 4.5698136555e-02, 2.7221106971e-02, -5.0282300258e-02, -5.1663864823e-02, 5.0987249628e-02, 9.0485392483e-02, -4.1603111790e-02, -1.6361436263e-01, -1.0704456365e-02, 3.5628695792e-01, 5.5459922084e-01, 3.5628695792e-01, -1.0704456365e-02, -1.6361436263e-01, -4.1603111790e-02, 9.0485392483e-02, 5.0987249628e-02, -5.1663864823e-02, -5.0282300258e-02, 2.7221106971e-02, 4.5698136555e-02, -1.0679394699e-02, -3.9282618887e-02, -6.4695302151e-04, 3.2057724080e-02, 8.1251717279e-03, -2.4690698016e-02, -1.2608162870e-02, 1.7670980642e-02, 1.4735662483e-02, -1.1359609346e-02, -1.5052324818e-02, 6.0029171665e-03, 1.4049779174e-02, -1.7386657056e-03, -1.2175276174e-02, -1.3969575800e-03, 9.8237515984e-03, 3.4540124085e-03, -7.3301527521e-03, -4.5537073976e-03, 4.9583669373e-03, 4.8663498835e-03, -2.8966063910e-03, -4.5890114465e-03, 1.2579439516e-03, 3.9239359768e-03, -8.6386881070e-05, -3.0596594938e-03, -6.3230621305e-04, 2.1563565688e-03, 9.5648007150e-04, -1.3363233256e-03, -9.7283144780e-04, 6.7984527906e-04, 7.8079557647e-04, -2.2609003083e-04, -4.7861967162e-04, -2.1850002011e-05, 1.5224742206e-04, 8.8784066371e-05, 1.3182485134e-04, -1.8305167738e-05, -3.3071450507e-04, -1.3743221406e-04, 4.2496083963e-04, 3.2634180427e-04, -4.1582530241e-04, -5.0340105072e-04, 3.2048789072e-04, 6.3529569901e-04, -1.6617637952e-04, -7.0258143521e-04, -1.5827253275e-05, 6.9955714665e-04, 1.9550609650e-04, -6.3230445935e-04, -3.4818706949e-04, 5.1550012249e-04, 4.5707019142e-04, -3.6866549936e-04, -5.1416395507e-04, 2.1246715982e-04, 5.1978739429e-04, -6.5614839363e-05, -4.8108463752e-04, -5.7507336159e-05, 4.0968443718e-04, 1.4796009669e-04, -3.1934040767e-04, -2.0251435162e-04, 2.2363993628e-04, 2.2301952102e-04, -1.3418896425e-04, -2.1517847459e-04, 5.9427713818e-05, 1.8701663321e-04, -4.1258453650e-06, -1.4732577300e-04, -3.0503826568e-05, 1.0431120674e-04, 4.6210324771e-05, -6.4599447382e-05, -4.6811898990e-05, 3.2677486281e-05, 3.7195306717e-05, -1.0759547197e-05, -2.2380212454e-05, -9.9796014867e-07, 6.7506282624e-06, 3.9982503227e-06, 6.4094323907e-06, -6.2897066014e-07, -1.5147259248e-05, -6.3558764252e-06, 1.8800552428e-05, 1.4356250995e-05, -1.7771633363e-05, -2.1299612136e-05, 1.3190154000e-05, 2.5842003924e-05, -6.5427500664e-06, -2.7404912150e-05, -6.6454989299e-07, 2.6079710827e-05, 7.1644345011e-06, -2.2446408027e-05, -1.2084227227e-05, 1.7356048979e-05, 1.4997961053e-05, -1.1721675486e-05, -1.5891625499e-05, 6.3487776401e-06, 1.5064716289e-05, -1.8303781261e-06, -1.3009229990e-05, -1.5024372933e-06, 1.0280353312e-05, 3.5688710327e-06, -7.3916945269e-06, -4.4887077258e-06, 4.7436885121e-06, 4.5112332508e-06, -2.5897362011e-06, -3.9407657887e-06, 1.0362499293e-06, 3.0726845332e-06, -6.7829977410e-08, -2.1485949525e-06, -4.1364098644e-07, 1.3334649132e-06, 5.4673392936e-07, -7.1290982678e-07, -4.7367916408e-07, 3.0541061907e-07, 3.1421287283e-07, -8.3024102014e-08, -1.5212421546e-07, -6.2515870285e-09, 3.2714281320e-08, 1.8580664775e-08, 3.0903860136e-08, -7.7431048180e-10, -4.7275060561e-08, -1.6472113056e-08}
  COEFFICIENT_WIDTH 24
  QUANTIZATION Quantize_Only
  BESTPRECISION true
  FILTER_TYPE Decimation
  DECIMATION_RATE 2
  NUMBER_CHANNELS 2
  NUMBER_PATHS 1
  SAMPLE_FREQUENCY 5.0
  CLOCK_FREQUENCY 125
  OUTPUT_ROUNDING_MODE Convergent_Rounding_to_Even
  OUTPUT_WIDTH 26
  M_DATA_HAS_TREADY true
  HAS_ARESETN true
} {
  S_AXIS_DATA conv_0/M_AXIS
  aclk $fclk
  aresetn $f_aresetn
}

# Create axis_subset_converter
cell xilinx.com:ip:axis_subset_converter:1.1 subset_0 {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  M_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 4
  M_TDATA_NUM_BYTES 3
  TDATA_REMAP {tdata[23:0]}
} {
  S_AXIS fir_0/M_AXIS_DATA
  aclk $fclk
  aresetn $f_aresetn
}

# Create floating_point
cell xilinx.com:ip:floating_point:7.1 fp_0 {
  OPERATION_TYPE Fixed_to_float
  A_PRECISION_TYPE.VALUE_SRC USER
  C_A_EXPONENT_WIDTH.VALUE_SRC USER
  C_A_FRACTION_WIDTH.VALUE_SRC USER
  A_PRECISION_TYPE Custom
  C_A_EXPONENT_WIDTH 2
  C_A_FRACTION_WIDTH 22
  RESULT_PRECISION_TYPE Single
  HAS_ARESETN true
} {
  S_AXIS_A subset_0/M_AXIS
  aclk $fclk
  aresetn $f_aresetn
}

# Create axis_dwidth_converter
cell xilinx.com:ip:axis_dwidth_converter:1.1 conv_1 {
  S_TDATA_NUM_BYTES.VALUE_SRC USER
  S_TDATA_NUM_BYTES 4
  M_TDATA_NUM_BYTES 8
} {
  S_AXIS fp_0/M_AXIS_RESULT
  aclk $fclk
  aresetn $f_aresetn
}

cell open-mri:user:axis_dma_rx:1.0 axis_dma_rx_0 {
  C_S_AXI_ADDR_WIDTH 16
  C_S_AXI_DATA_WIDTH 32
  C_AXIS_TDATA_WIDTH 64
} {
  aclk      $fclk
  aresetn   $f_aresetn
}
#  S_AXIS    conv_1/M_AXIS
#  gate      slice_0/Dout

cell xilinx.com:ip:axi_datamover:5.1 axi_datamover_0 {
  c_include_mm2s            Omit
  c_include_mm2s_stsfifo    false
  c_m_axi_s2mm_data_width   64
  c_s_axis_s2mm_tdata_width 64
  c_s2mm_support_indet_btt  true
  c_enable_mm2s             0
} {
  m_axi_s2mm_aclk             $fclk
  m_axis_s2mm_cmdsts_awclk    $fclk
  m_axis_s2mm_cmdsts_aresetn  $f_aresetn
  m_axi_s2mm_aresetn          $f_aresetn
  s2mm_err                    axis_dma_rx_0/s2mm_err
  M_AXIS_S2MM_STS             axis_dma_rx_0/S_AXIS_S2MM_STS
  S_AXIS_S2MM                 axis_dma_rx_0/M_AXIS_S2MM
  S_AXIS_S2MM_CMD             axis_dma_rx_0/M_AXIS_S2MM_CMD
}
cell open-mri:user:axi_sniffer:1.0 axi_sniffer_0 {
  C_S_AXI_ADDR_WIDTH 32
  C_S_AXI_DATA_WIDTH 64
} {
  aclk      $fclk
  aresetn   $f_aresetn
  bresp     axis_dma_rx_0/axi_mm_bresp
  bvalid    axis_dma_rx_0/axi_mm_bvalid
  bready    axis_dma_rx_0/axi_mm_bready
}
set_property CONFIG.PROTOCOL AXI4 [get_bd_intf_pins /rx_0/axi_sniffer_0/S_AXI]
save_bd_design
if { [dict get $pl_param_dict mode] == "SIMPLE"} {
    cell open-mri:user:axis_acq_trigger:1.0 axis_acq_trigger_0 {
        C_S_AXI_ADDR_WIDTH 12
        C_S_AXI_DATA_WIDTH 32
        C_AXIS_TDATA_WIDTH 64
    } {
        aclk      $fclk
        aresetn   $f_aresetn
        S_AXIS    conv_1/M_AXIS
        acq_len_out axis_dma_rx_0/acq_len_in
    }
    save_bd_design
    cell xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_0 {
        TDATA_NUM_BYTES 8
        FIFO_DEPTH 16
    } {
        s_axis_aclk $fclk
        s_axis_aresetn axis_acq_trigger_0/resetn_out
        s_axis axis_acq_trigger_0/M_AXIS
        m_axis axis_dma_rx_0/S_AXIS
    }
    save_bd_design
    connect_bd_net [get_bd_pins axis_acq_trigger_0/gate_out] [get_bd_pins axis_dma_rx_0/gate]
} else {
    connect_bd_intf_net [get_bd_intf_pins conv_1/M_AXIS] [get_bd_intf_pins axis_dma_rx_0/S_AXIS]
    connect_bd_net [get_bd_pins slice_0/Dout]  [get_bd_pins axis_dma_rx_0/gate]
}