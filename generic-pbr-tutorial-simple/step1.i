# ==============================================================================
#
# ==============================================================================

bed_height = 10.0
bed_radius = 1.2
bed_porosity = 0.39
outlet_pressure = 1
T_fluid = 300
density = 8.60161

mass_flow_rate = 60.0
flow_area = '${fparse pi * bed_radius * bed_radius}'
flow_vel = '${fparse mass_flow_rate / flow_area / density}'

rho = ${density}
mu = 2.0e-5   #estimation because I can't find the info in HeliumFluidProperties, to investigate
advected_interp_method = 'upwind'   # same as other simple imput files

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
  # coord_type = RZ
[]

# same as other simple imput files
[Problem]
  linear_sys_names = 'u_system v_system pressure_system'
  previous_nl_solution_required = true
[]


[UserObjects]
  [rc]
    type = RhieChowMassFlux
    u = superficial_u
    v = superficial_v
    pressure = pressure
    rho = ${rho}
    # porosity = porosity
    p_diffusion_kernel = p_diffusion

    # pressure_baffle_sidesets = 'baffle baffle2 baffle3'
    # pressure_gradient_limiter = 'baffle baffle2 baffle3'
    # baffle_form_loss = ${bf}
    # velocity_form_loss = 'lower_epsilon lower_epsilon lower_epsilon' #the old solver does it himself, it decides wether to use the velocity before or after to compute form loss
    # pressure_gradient_limiter_blend = 0.5
    # pressure_baffle_relaxation = 0.2
    # debug_baffle = false

    # use_flux_velocity_reconstruction = false
    # use_reconstructed_pressure_gradient = false
    # flux_velocity_reconstruction_relaxation = 1.0

    # # flux_velocity_reconstruction_zero_flux_sidesets = 'top_to_1 top_to_2 top_to_3 top_to_4 bottom_to_1 bottom_to_2 bottom_to_3 bottom_to_4'
    # flux_velocity_reconstruction_zero_flux_sidesets = 'left right'
    
    # use_corrected_pressure_gradient = false
    # # body_force_kernel_names = "u_friction; v_friction"
    # reconstructed_pressure_gradient_feedback_relaxation = 0.1
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
    initial_condition = 0
  []
  [pressure]
    type = MooseLinearVariableFVReal
    solver_sys = pressure_system
    initial_condition = ${outlet_pressure}
  []
[]

[LinearFVKernels]
  [u_advection]
    type = LinearWCNSFVMomentumFlux
    variable = superficial_u
    advected_interp_method = ${advected_interp_method}
    mu = ${mu}
    u = superficial_u
    v = superficial_v
    momentum_component = 'x'
    rhie_chow_user_object = rc
    use_nonorthogonal_correction = false
    # porosity_outside_divergence = true
    # use_two_point_stress_transmissibility = true
  []
  [v_advection]
    type = LinearWCNSFVMomentumFlux
    variable = superficial_v
    advected_interp_method = ${advected_interp_method}
    mu = ${mu}
    u = superficial_u
    v = superficial_v
    momentum_component = 'y'
    rhie_chow_user_object = rc
    use_nonorthogonal_correction = false
    # porosity_outside_divergence = true
    # use_two_point_stress_transmissibility = true
  []
  # [u_advection]
  #   type = PorousLinearWCNSFVMomentumFlux
  #   variable = superficial_u
  #   advected_interp_method = ${advected_interp_method}
  #   mu = ${mu}
  #   u = superficial_u
  #   v = superficial_v
  #   momentum_component = 'x'
  #   rhie_chow_user_object = rc
  #   use_nonorthogonal_correction = false
  #   porosity_outside_divergence = true
  #   use_two_point_stress_transmissibility = true
  # []
  # [v_advection]
  #   type = PorousLinearWCNSFVMomentumFlux
  #   variable = superficial_v
  #   advected_interp_method = ${advected_interp_method}
  #   mu = ${mu}
  #   u = superficial_u
  #   v = superficial_v
  #   momentum_component = 'y'
  #   rhie_chow_user_object = rc
  #   use_nonorthogonal_correction = false
  #   porosity_outside_divergence = true
  #   use_two_point_stress_transmissibility = true
  # []
  # [u_pressure]
  #   type = LinearFVMomentumPressureUO
  #   variable = superficial_u
  #   momentum_component = 'x'
  #   rhie_chow_user_object = rc
  #   porosity = porosity
  #   use_corrected_gradient = false
  # []
  # [v_pressure]
  #   type = LinearFVMomentumPressureUO
  #   variable = superficial_v
  #   momentum_component = 'y'
  #   rhie_chow_user_object = rc
  #   porosity = porosity
  #   use_corrected_gradient = false
  # []
  [u_pressure]
    type = LinearFVMomentumPressure
    variable = superficial_u
    momentum_component = 'x'
    # rhie_chow_user_object = rc
    pressure = pressure
    # porosity = porosity
    # use_corrected_gradient = false
  []
  [v_pressure]
    type = LinearFVMomentumPressure
    variable = superficial_v
    momentum_component = 'y'
    pressure=pressure
    # rhie_chow_user_object = rc
    # porosity = porosity
    # use_corrected_gradient = false
  []
  # [p_diffusion]
  #   type = LinearFVAnisotropicDiffusionJump
  #   variable = pressure
  #   diffusion_tensor = Ainv
  #   rhie_chow_user_object = rc
  #   use_nonorthogonal_correction = false
  #   debug_baffle_jump = false
  # []

  [p_diffusion]
    type = LinearFVAnisotropicDiffusion
    variable = pressure
    diffusion_tensor = Ainv
    # rhie_chow_user_object = rc
    use_nonorthogonal_correction = false
    # debug_baffle_jump = false1
  []
  [HbyA_divergence]
    type = LinearFVDivergence
    variable = pressure
    face_flux = HbyA
    force_boundary_execution = true
  []
[]

[LinearFVBCs]


  [inlet_u]
    type = LinearFVAdvectionDiffusionFunctorDirichletBC
    boundary = bottom
    variable = superficial_u
    functor = 0
  []
  [inlet_v]
    type = LinearFVAdvectionDiffusionFunctorDirichletBC
    boundary = bottom
    variable = superficial_v
    functor = ${flow_vel}
  []


  # as in other imput files - makes velocity outlet fixed by the inside of the domain?
  [outlet_u]
    type = LinearFVAdvectionDiffusionOutflowBC
    boundary = top
    variable = superficial_u
    use_two_term_expansion = false
  []
  [outlet_v]
    type = LinearFVAdvectionDiffusionOutflowBC
    boundary = top
    variable = superficial_v
    use_two_term_expansion = false
  []



  [outlet_p]
    type = LinearFVAdvectionDiffusionFunctorDirichletBC
    boundary = top
    variable = pressure
    functor = ${outlet_pressure}
  []



  [symmetry-u]
    type = LinearFVVelocitySymmetryBC
    boundary = 'left right'
    # boundary = 'left'
    variable = superficial_u
    u = superficial_u
    v = superficial_v
    momentum_component = x
  []
  [symmetry-v]
    type = LinearFVVelocitySymmetryBC
    boundary = 'left right'
    # boundary = 'left'
    variable = superficial_v
    u = superficial_u
    v = superficial_v
    momentum_component = y
  []

  # [wall-u]
  #   type = LinearFVAdvectionDiffusionFunctorDirichletBC
  #   boundary = 'right'
  #   variable = superficial_u
  #   functor = 0
  # []
  # [wall-v]
  #   type = LinearFVAdvectionDiffusionFunctorDirichletBC
  #   boundary = 'right'
  #   variable = superficial_v
  #   functor = 0
  # []
  # [pressure_extrapol]
  #   type = LinearFVExtrapolatedPressureBC
  #   boundary = 'bottom'
  #   use_two_term_expansion = false
  #   variable = pressure
  # []
  [pressure_symmetry]
    type = LinearFVPressureSymmetryBC
    boundary = 'left right'
    # boundary = 'left'
    variable = pressure
    HbyA_flux = 'HbyA'
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


#exactly the same
[Executioner]
  type = SIMPLE
  momentum_l_abs_tol = 1e-16
  pressure_l_abs_tol = 1e-16
  momentum_l_tol = 0
  pressure_l_tol = 0
  rhie_chow_user_object = rc
  momentum_systems = 'u_system v_system'
  pressure_system = pressure_system
  momentum_equation_relaxation = 0.2
  pressure_variable_relaxation = 0.1
  num_iterations = 15
  pressure_absolute_tolerance = 1e-8
  momentum_absolute_tolerance = 1e-8
  momentum_petsc_options_iname = '-pc_type -pc_hypre_type'
  momentum_petsc_options_value = 'hypre boomeramg'
  pressure_petsc_options_iname = '-pc_type -pc_hypre_type'
  pressure_petsc_options_value = 'hypre boomeramg'
  continue_on_max_its = true
[]


[Postprocessors]
  # reference values
  [desired_mfr]
    type = Receiver
    default = ${mass_flow_rate}
  []
  [fluid_temperature]
    type = Receiver
    default = ${T_fluid}
  []

  # mass flow rates (with Rhie–Chow)
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

  # pure volumetric flux (no density effect)
  [inlet_vflux]
    type = VolumetricFlowRate
    advected_quantity = 1
    vel_x = superficial_u
    vel_y = superficial_v
    boundary = top
    rhie_chow_user_object = rc
  []
  [outlet_vflux]
    type = VolumetricFlowRate
    advected_quantity = 1
    vel_x = superficial_u
    vel_y = superficial_v
    boundary = bottom
    rhie_chow_user_object = rc
  []

  # global extrema (catch first variable to blow up)
  [p_min]
    type = ElementExtremeValue
    variable = pressure
    value_type = min
  []
  [p_max]
    type = ElementExtremeValue
    variable = pressure
    value_type = max
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

  # boundary averages (localize outlet behavior)
  [top_p_avg]
    type = SideAverageValue
    variable = pressure
    boundary = top
  []
  [bottom_p_avg]
    type = SideAverageValue
    variable = pressure
    boundary = bottom
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

  # boundary extrema (detect corner blow-up at outlet)
  [bottom_p_min]
    type = SideExtremeValue
    variable = pressure
    boundary = bottom
    value_type = min
  []
  [bottom_p_max]
    type = SideExtremeValue
    variable = pressure
    boundary = bottom
    value_type = max
  []

  [bottom_v_min]
    type = SideExtremeValue
    variable = superficial_v
    boundary = bottom
    value_type = min
  []
  [bottom_v_max]
    type = SideExtremeValue
    variable = superficial_v
    boundary = bottom
    value_type = max
  []
[]

[Outputs]
  exodus = true
  csv = true
  execute_on = 'timestep_end'
[]
