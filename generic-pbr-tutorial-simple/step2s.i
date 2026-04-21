mu = 2e-3 # 1e-2
rho = 8.60161 
# rho = 1e3
advected_interp_method = 'upwind'
bed_radius = 1.2
bed_height = 10.0
bed_porosity = 0.39
# forcheimer = 52
# bf = '0 0 0'

mass_flow_rate = 60.0   #value with low rho
# mass_flow_rate = 6960  #value with high rho
flow_area = '${fparse pi * bed_radius * bed_radius}'
flow_vel = '${fparse mass_flow_rate / (flow_area * rho)}'

[Mesh]
  [gen]
    type = GeneratedMeshGenerator
    dim = 2
    xmin = 0
    xmax = ${bed_radius}
    ymin = 0
    ymax = ${bed_height}
    nx = 6
    ny = 40
  []
  coord_type = RZ
[]

[Problem]
  linear_sys_names = 'u_system v_system pressure_system'
  previous_nl_solution_required = true
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
    pressure_baffle_sidesets = 'baffle baffle2 baffle3'
    # pressure_gradient_limiter = 'baffle baffle2 baffle3'
    # baffle_form_loss = ${bf}
    # velocity_form_loss = 'lower_epsilon lower_epsilon higher_epsilon'
    # pressure_gradient_limiter_blend = 0.5
    pressure_baffle_relaxation = 0.1
    debug_baffle = false
    use_flux_velocity_reconstruction = true
    use_reconstructed_pressure_gradient = true
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
    initial_condition = 0.0
  []
[]

[LinearFVKernels]
  [u_advection]
    type = PorousLinearWCNSFVMomentumFlux
    variable = superficial_u
    advected_interp_method = ${advected_interp_method}
    mu = ${mu}
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
    mu = ${mu}
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
    Forchheimer_name = forch
    porosity = porosity
    rho = ${rho}
    u = superficial_u
    v = superficial_v
    momentum_component = 'x'
  []
  [v_friction]
    type = LinearFVMomentumPorousFriction
    variable = superficial_v
    Forchheimer_name = forch
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
[]


[AuxVariables]
  [porosity]
    family = MONOMIAL
    order = CONSTANT
    fv = true
    initial_condition = ${bed_porosity}
  []
[]

[FunctorMaterials]
  [friction]
    type = ADGenericVectorFunctorMaterial
    prop_names = 'forch'
    prop_values = '10.14 10.14 10.14'  #f_F,simple = f_F,newton * porosity/2
  []
[]


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
[]

[AuxVariables]
  [porosity_aux]
    type = MooseLinearVariableFVReal
  []
[]

[AuxKernels]
  [por]
    type = FunctorAux
    variable = porosity_aux
    functor = porosity
    execute_on = 'timestep_end'
  []
[]

[Executioner]
  type = SIMPLE
  momentum_l_abs_tol = 1e-14
  pressure_l_abs_tol = 1e-14
  momentum_l_tol = 0
  pressure_l_tol = 0
  rhie_chow_user_object = rc
  momentum_systems = 'u_system v_system'
  pressure_system = pressure_system
  momentum_equation_relaxation = 0.4
  pressure_variable_relaxation = 0.1
  num_iterations = 250
  pressure_absolute_tolerance = 1e-8
  momentum_absolute_tolerance = 1e-8
  momentum_petsc_options_iname = '-pc_type -pc_hypre_type'
  momentum_petsc_options_value = 'hypre boomeramg'
  pressure_petsc_options_iname = '-pc_type -pc_hypre_type'
  pressure_petsc_options_value = 'hypre boomeramg'
  # print_fields = true
  continue_on_max_its = true
[]

[Outputs]
  exodus = true
  # csv = true
  # execute_on = 'timestep_end'
[]
