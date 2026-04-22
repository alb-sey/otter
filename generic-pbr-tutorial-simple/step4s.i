# mu = 3.5e-5 # 1e-2
rho = 8.7325
# rho = 1e3
advected_interp_method = 'upwind'
bed_radius = 1.2
bed_height = 10.0
bed_porosity = 0.39
cavity_height = 0.5
# forcheimer = 52
# bf = '0 0 0'

T_inlet = 300

cp_f = 5200          #pretty sure that's not accurate, it varies with temperature
k_f = 0.25           # same issue
kappa_h = '${fparse k_f / cp_f}'
# rho_s = 2000        
# cp_s = 300          
k_s = 20             
alpha = 2e4          # volumetric interphase heat transfer coefficient
# thermal_mass_scaling = 1

power_fn_scaling = 0.88689239556
offset = 0.56331

mass_flow_rate = 60.0   #value with low rho
# mass_flow_rate = 6960  #value with high rho
flow_area = '${fparse pi * bed_radius * bed_radius}'
flow_vel = '${fparse mass_flow_rate / (flow_area * rho)}'
h_inlet = '${fparse cp_f * T_inlet}'

[Mesh]
  [gen]
    type = CartesianMeshGenerator
    dim = 2
    dx = '${bed_radius}'
    ix = '6'
    dy = '${bed_height} ${cavity_height}'
    iy = '40            2'
    subdomain_id = '1 2'
  []


  [rename_blocks]
    type = RenameBlockGenerator
    old_block = '1 2'
    new_block = 'bed cavity'
    input = gen
  []

  [baffle]
    type = SideSetsBetweenSubdomainsGenerator
    input = rename_blocks
    primary_block = 'bed'
    paired_block = 'cavity'
    new_boundary = 'baffle'
  []
  coord_type = RZ

[]

[FluidProperties]
  [fp]
    type = HeliumFluidProperties
  []
[]

[Problem]
  linear_sys_names = 'u_system v_system pressure_system energy_system solid_energy_system'
  previous_nl_solution_required = true
[]

[Functions]
  [heat_source_fn]
    type = ParsedFunction
    expression = '${power_fn_scaling} * (-1.0612e4 * pow(y+${offset}, 4) + 1.5963e5 * pow(y+${offset}, 3)
                   -6.2993e5 * pow(y+${offset}, 2) + 1.4199e6 * (y+${offset}) + 5.5402e4)'
  []
[]

[UserObjects]
  [rc]
    type = PorousRhieChowMassFlux
    u = superficial_u
    v = superficial_v
    pressure = pressure
    rho = ${rho}
    porosity = porosity
    p_diffusion_kernel = p_diffusion
    # pressure_baffle_sidesets = 'baffle'
    # pressure_gradient_limiter = 'baffle baffle2 baffle3'
    # baffle_form_loss = ${bf}
    # velocity_form_loss = 'lower_epsilon lower_epsilon higher_epsilon'
    # pressure_gradient_limiter_blend = 0.5
    pressure_baffle_relaxation = 0.1
    debug_baffle = false
    use_flux_velocity_reconstruction = false
    use_reconstructed_pressure_gradient = false
    flux_velocity_reconstruction_relaxation = 1.0
    # flux_velocity_reconstruction_zero_flux_sidesets = 'top_to_1 top_to_2 top_to_3 top_to_4 bottom_to_1 bottom_to_2 bottom_to_3 bottom_to_4'
    flux_velocity_reconstruction_zero_flux_sidesets = 'right left'

    
    use_corrected_pressure_gradient = false
    # body_force_kernel_names = "u_friction; v_friction"
    reconstructed_pressure_gradient_feedback_relaxation = 0.2
  []
[]

[Variables]
  [superficial_u]
    type = MooseLinearVariableFVReal
    solver_sys = u_system
    initial_condition = 0
  []
  [superficial_v]
    type = MooseLinearVariableFVReal
    solver_sys = v_system
    initial_condition = -${flow_vel}
  []
  [pressure]
    type = MooseLinearVariableFVReal
    solver_sys = pressure_system
    initial_condition = 5e6
  []

  [h_fluid]
    type = MooseLinearVariableFVReal
    solver_sys = energy_system
    initial_condition = ${h_inlet}
  []

  [T_solid]
    type = MooseLinearVariableFVReal
    solver_sys = solid_energy_system
    initial_condition = ${T_inlet}
    block = 'bed'
  []
[]

[LinearFVKernels]
  [u_advection]
    type = PorousLinearWCNSFVMomentumFlux
    variable = superficial_u
    advected_interp_method = ${advected_interp_method}
    mu = mu
    u = superficial_u
    v = superficial_v
    momentum_component = 'x'
    rhie_chow_user_object = rc
    use_nonorthogonal_correction = false
    porosity_outside_divergence = true
    use_two_point_stress_transmissibility = true
  []
  [v_advection]
    type = PorousLinearWCNSFVMomentumFlux
    variable = superficial_v
    advected_interp_method = ${advected_interp_method}
    mu = mu
    u = superficial_u
    v = superficial_v
    momentum_component = 'y'
    rhie_chow_user_object = rc
    use_nonorthogonal_correction = false
    porosity_outside_divergence = true
    use_two_point_stress_transmissibility = true
  []
  [u_pressure]
    type = LinearFVMomentumPressureUO
    variable = superficial_u
    momentum_component = 'x'
    rhie_chow_user_object = rc
    porosity = porosity
    use_corrected_gradient = true
  []
  [v_pressure]
    type = LinearFVMomentumPressureUO
    variable = superficial_v
    momentum_component = 'y'
    rhie_chow_user_object = rc
    porosity = porosity
    use_corrected_gradient = true
  []
  [u_friction]
    type = LinearFVMomentumPorousFriction
    variable = superficial_u
    Forchheimer_name = Forchheimer_coefficient
    porosity = porosity
    rho = ${rho}
    u = superficial_u
    v = superficial_v
    momentum_component = 'x'
  []
  [v_friction]
    type = LinearFVMomentumPorousFriction
    variable = superficial_v
    Forchheimer_name = Forchheimer_coefficient
    porosity = porosity
    rho = ${rho}
    u = superficial_u
    v = superficial_v
    momentum_component = 'y'
  []
  [p_diffusion]
    type = LinearFVAnisotropicDiffusionJump
    variable = pressure
    diffusion_tensor = Ainv
    rhie_chow_user_object = rc
    use_nonorthogonal_correction = false
    debug_baffle_jump = false
  []
  [HbyA_divergence]
    type = LinearFVDivergence
    variable = pressure
    face_flux = HbyA
    force_boundary_execution = true
  []

  [fluid_energy_advection]
    type = LinearFVEnergyAdvection
    variable = h_fluid
    advected_quantity = enthalpy
    advected_interp_method = ${advected_interp_method}
    rhie_chow_user_object = rc
  []

  [fluid_energy_diffusion]
    type = LinearFVDiffusion
    variable = h_fluid
    diffusion_coeff = kappa_h
    use_nonorthogonal_correction = false
  []

  [fluid_solid_exchange]
    type = LinearFVEnthalpyVolumetricHeatTransfer
    variable = h_fluid
    h_solid_fluid = alpha
    cp = cp_f
    T_fluid = T_fluid
    T_solid = T_solid
    is_solid = false
    block = 'bed'
  []

  [solid_energy_diffusion]
    type = LinearFVDiffusion
    variable = T_solid
    diffusion_coeff = kappa_s
    use_nonorthogonal_correction = false
    block = 'bed'
  []

  [source]
    type = LinearFVSource
    variable = T_solid
    source_density = heat_source_fn
    block = 'bed'
  []

  [convection_pebble_bed_fluid]
    type = LinearFVEnthalpyVolumetricHeatTransfer
    variable = T_solid
    h_solid_fluid = alpha
    cp = 1.0
    T_fluid = T_fluid
    T_solid = T_solid
    is_solid = true
    block = 'bed'
  []
[]

[LinearFVBCs]

  [top_u]
    type = LinearFVAdvectionDiffusionFunctorDirichletBC
    boundary = top
    variable = superficial_u
    functor = 0.0
  []
  [bottom_u]
    type = LinearFVAdvectionDiffusionOutflowBC
    boundary = bottom
    variable = superficial_u
    use_two_term_expansion = false
  []

  [top_v]
    type = LinearFVAdvectionDiffusionFunctorDirichletBC
    boundary = top
    variable = superficial_v
    functor = -${flow_vel}
  []
  [bottom_v]
    type = LinearFVAdvectionDiffusionOutflowBC
    boundary = bottom
    variable = superficial_v
    use_two_term_expansion = false
  []


  [symmetry-u]
    type = LinearFVVelocitySymmetryBC
    boundary = 'left right'
    variable = superficial_u
    u = superficial_u
    v = superficial_v
    momentum_component = x
  []
  [symmetry-v]
    type = LinearFVVelocitySymmetryBC
    boundary = 'left right'
    variable = superficial_v
    u = superficial_u
    v = superficial_v
    momentum_component = y
  []

  [outlet_p]
    type = LinearFVAdvectionDiffusionFunctorDirichletBC
    boundary = bottom
    variable = pressure
    functor = 5.5e6
  []


  [pressure-symmetry]
    type = LinearFVPressureSymmetryBC
    boundary = 'left right'
    variable = pressure
    HbyA_flux = 'HbyA' # Functor created in the RhieChowMassFlux UO
  []

  [top_h_fluid]
    type = LinearFVAdvectionDiffusionFunctorDirichletBC
    boundary = top
    variable = h_fluid
    functor = h_from_p_T
  []

  [side_h_fluid]
    type = LinearFVAdvectionDiffusionFunctorNeumannBC
    boundary = 'left right'
    variable = h_fluid
    functor = 0.0
    diffusion_coeff = kappa_h
  []

  [bottom_h_fluid]
    type = LinearFVAdvectionDiffusionOutflowBC
    boundary = bottom
    variable = h_fluid
    use_two_term_expansion = false
  []

  [side_T_solid]
    type = LinearFVAdvectionDiffusionFunctorNeumannBC
    boundary = 'left right'
    variable = T_solid
    functor = 0.0
    diffusion_coeff = kappa_s
  []
[]


# [FunctorMaterials]
#   [friction]
#     type = ADGenericVectorFunctorMaterial
#     prop_names = 'forch'
#     prop_values = '10.14 10.14 10.14'  #f_F,simple = f_F,newton * porosity/2
#   []
# []

[FunctorMaterials]

  # [const_drag]
  #   type = GenericVectorFunctorMaterial
  #   prop_names = 'Darcy_coefficient'
  #   prop_values = '0 0 0'
  # []

  [drag_pebble_bed]
    type = GenericVectorFunctorMaterial
    prop_names = 'pb_forch'
    prop_values = '10.14 10.14 10.14'                  #f_F,simple = f_F,newton * porosity/2
  []

  [drag_cavity]
    type = GenericVectorFunctorMaterial
    prop_names = 'cav_forch'
    prop_values = '0 0 0'
  []

  [forch]
    type = PiecewiseByBlockVectorFunctorMaterial
    prop_name = 'Forchheimer_coefficient'
    subdomain_to_prop_value = 'bed pb_forch 
                              cavity cav_forch'
  []

  [porosity]
    type = PiecewiseByBlockFunctorMaterial
    prop_name = porosity
    subdomain_to_prop_value = 'bed ${bed_porosity}
                              cavity 1'
  []

  [fluid_constants]
    type = GenericFunctorMaterial
    prop_names = 'cp_f kappa_h'
    prop_values = '${cp_f} ${kappa_h}'
  []

  [solid_k]
    type = GenericFunctorMaterial
    prop_names = 'kappa_s'
    prop_values = '${k_s}'
    block = 'bed'
  []

  [alpha_mat]
    type = GenericFunctorMaterial
    prop_names = 'alpha'
    prop_values = '${alpha}'
    block = 'bed'
  []

  [fluid_enthalpy_material]
    type = LinearFVEnthalpyFunctorMaterial
    pressure = pressure
    T_fluid = T_fluid
    h = h_fluid
    fp=fp
  []


  [fluid_props]
    type = GeneralFunctorFluidProps
    fp = fp
    pressure = pressure
    # T_fluid = ${T_inlet}
    T_fluid = T_fluid
    speed = 1
    porosity = porosity
    characteristic_length = 0.06
  []


  # [rho_h]
  #   type = ParsedFunctorMaterial
  #   property_name = 'rho_h'
  #   functor_names = 'h_fluid'
  #   expression = '${rho} * h_fluid'
  # []
[]


# [AuxVariables]
#   [porosity]
#     type=PiecewiseConstantVariable
#   []
# []

# [ICs]
#   [p_bed]
#     type=ConstantIC
#     variable=porosity
#     value=${bed_porosity}
#     block=bed
#   []

#   [p_cavity]
#     type=ConstantIC
#     variable=porosity
#     value=1
#     block=cavity
#   []
# []


[Postprocessors]
  [inlet_pressure]
    type = SideAverageValue
    variable = pressure
    boundary = top
    outputs = none
  []

  [outlet_pressure]
    type = SideAverageValue
    variable = pressure
    boundary = bottom
    outputs = none
  []

  [pressure_drop]
    type = ParsedPostprocessor
    pp_names = 'inlet_pressure outlet_pressure'
    expression = 'inlet_pressure - outlet_pressure'
  []

  [desired_mfr]
    type = Receiver
    default = ${mass_flow_rate}
  []

  [inlet_mfr]
    type = VolumetricFlowRate
    advected_quantity = ${rho}
    vel_x = superficial_u
    vel_y = superficial_v
    boundary = top
    rhie_chow_user_object = rc
  []
  [outlet_mfr]
    type = VolumetricFlowRate
    advected_quantity = ${rho}
    vel_x = superficial_u
    vel_y = superficial_v
    boundary = bottom
    rhie_chow_user_object = rc
  []

  [u_min]
    type = ElementExtremeValue
    variable = superficial_u
    value_type = min
  []
  [u_max]
    type = ElementExtremeValue
    variable = superficial_u
    value_type = max
  []

  [v_min]
    type = ElementExtremeValue
    variable = superficial_v
    value_type = min
  []
  [v_max]
    type = ElementExtremeValue
    variable = superficial_v
    value_type = max
  []


  [top_v_avg]
    type = SideAverageValue
    variable = superficial_v
    boundary = top
  []
  [bottom_v_avg]
    type = SideAverageValue
    variable = superficial_v
    boundary = bottom
  []

  [enthalpy_inlet]
    type = VolumetricFlowRate
    advected_quantity = h_fluid
    vel_x = superficial_u
    vel_y = superficial_v
    boundary = top
    rhie_chow_user_object = rc
  []

  [enthalpy_outlet]
    type = VolumetricFlowRate
    advected_quantity = h_fluid
    vel_x = superficial_u
    vel_y = superficial_v
    boundary = bottom
    rhie_chow_user_object = rc
    advected_interp_method = upwind
  []

  [heat_source_integral]
    type = ElementIntegralFunctorPostprocessor
    functor = heat_source_fn
    block = bed
  []

  [T_solid_max]
    type = ElementExtremeValue
    variable = T_solid
    value_type = max
    block = bed
  []

  [T_outlet_avg]
    type = SideAverageValue
    variable = T_fluid
    boundary = bottom
  []
[]

[AuxVariables]
  [porosity_aux]
    type = MooseLinearVariableFVReal
  []
  [T_fluid]
    type = MooseLinearVariableFVReal
    initial_condition = ${T_inlet}
  []

  [rho_var]
    type = MooseLinearVariableFVReal
  []
[]

[AuxKernels]
  [rho_out]
    type = FunctorAux
    functor = rho
    variable = rho_var
    execute_on = NONLINEAR
  []
  [por]
    type = FunctorAux
    variable = porosity_aux
    functor = porosity
    execute_on = 'timestep_end'
  []
  [fluid_temperature]
    type = FunctorAux
    variable = T_fluid
    functor = T_from_p_h
    execute_on = NONLINEAR
  []
[]

[Executioner]
  type = SIMPLE

  rhie_chow_user_object = rc

  momentum_systems = 'u_system v_system'
  pressure_system = pressure_system
  energy_system = energy_system
  solid_energy_system = solid_energy_system

  momentum_l_abs_tol = 1e-14
  pressure_l_abs_tol = 1e-14
  energy_l_abs_tol = 1e-12
  solid_energy_l_abs_tol = 1e-12

  momentum_l_tol = 0
  pressure_l_tol = 0
  energy_l_tol = 0
  solid_energy_l_tol = 0

  momentum_equation_relaxation = 0.2
  pressure_variable_relaxation = 0.05
  energy_equation_relaxation = 0.9
  # if your version exposes it separately:
  # solid_energy_equation_relaxation = 0.9

  num_iterations = 250

  pressure_absolute_tolerance = 1e-8
  momentum_absolute_tolerance = 1e-8
  energy_absolute_tolerance = 1e-8
  solid_energy_absolute_tolerance = 1e-8

  momentum_petsc_options_iname = '-pc_type -pc_hypre_type'
  momentum_petsc_options_value = 'hypre boomeramg'
  pressure_petsc_options_iname = '-pc_type -pc_hypre_type'
  pressure_petsc_options_value = 'hypre boomeramg'
  energy_petsc_options_iname = '-pc_type -pc_hypre_type'
  energy_petsc_options_value = 'hypre boomeramg'
  solid_energy_petsc_options_iname = '-pc_type -pc_hypre_type'
  solid_energy_petsc_options_value = 'hypre boomeramg'

  continue_on_max_its = true
[]

[Outputs]
  exodus = true
[]
