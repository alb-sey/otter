
# mu = 1e-5
p_out = 5.5e6
rho_f = 8.60161 

bed_radius = 1.2
bed_height = 10.0
bed_porosity = 0.39
cavity_height = 0.5
bed_forch = 10.14

cp_f = 5200
k_f = 0.25
kappa_h = '${fparse k_f / cp_f}'

mass_flow_rate = 60.0   #value with low rho
flow_area = '${fparse pi * bed_radius * bed_radius}'
flow_vel = '${fparse mass_flow_rate / (flow_area * rho_f)}'

T_inlet = 300

advected_interp_method = 'upwind'

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

[Problem]
  linear_sys_names = 'u_system v_system pressure_system energy_system'
  previous_nl_solution_required = true
[]

[FluidProperties]
  [fp]
    type = HeliumFluidProperties
  []
[]

[UserObjects]
  [rc]
    type = PorousRhieChowMassFlux
    u = superficial_u
    v = superficial_v
    pressure = pressure
    rho = 'rho_aux'
    porosity = 'porosity'
    p_diffusion_kernel = p_diffusion

    pressure_baffle_sidesets = 'baffle'
    pressure_baffle_relaxation = 0.1

    debug_baffle = false

    use_flux_velocity_reconstruction = true
    use_reconstructed_pressure_gradient = true
    flux_velocity_reconstruction_relaxation = 1.0
    flux_velocity_reconstruction_zero_flux_sidesets = 'left right'
    # flux_velocity_reconstruction_zero_flux_sidesets = 'top_to_1 top_to_2 bottom_to_1 bottom_to_2'

    use_interpolated_density_in_bernoulli_jump = true
    # pressure_gradient_limiter = 'baffle'
    # pressure_gradient_limiter_blend = 1.0
    use_corrected_pressure_gradient = true
  []
[]

[Variables]
  [superficial_u]
    type = MooseLinearVariableFVReal
    solver_sys = u_system
    initial_condition = 0.0
  []
  [superficial_v]
    type = MooseLinearVariableFVReal
    solver_sys = v_system
    initial_condition = -${flow_vel}
  []
  [pressure]
    type = MooseLinearVariableFVReal
    solver_sys = pressure_system
    initial_condition = ${p_out}
  []

  [h_fluid]
    type = MooseLinearVariableFVReal
    solver_sys = energy_system
    initial_condition = 1e6
  []


[]

[LinearFVKernels]
  [u_advection]
    type = PorousLinearWCNSFVMomentumFlux
    variable = superficial_u
    advected_interp_method = ${advected_interp_method}
    mu = 'mu'
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
    mu = 'mu'
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
    porosity = 'porosity'
    use_corrected_gradient = true
  []
  [v_pressure]
    type = LinearFVMomentumPressureUO
    variable = superficial_v
    momentum_component = 'y'
    rhie_chow_user_object = rc
    porosity = 'porosity'
    use_corrected_gradient = true
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

  [u_friction]
    type = LinearFVMomentumPorousFriction
    variable = superficial_u
    Forchheimer_name = Forchheimer_coefficient
    porosity = porosity
    rho = rho_aux
    u = superficial_u
    v = superficial_v
    momentum_component = 'x'
  []

  [v_friction]
    type = LinearFVMomentumPorousFriction
    variable = superficial_v
    Forchheimer_name = Forchheimer_coefficient
    porosity = porosity
    rho = rho_aux
    u = superficial_u
    v = superficial_v
    momentum_component = 'y'
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
[]

[LinearFVBCs]
  [inlet_u]
    type = LinearFVAdvectionDiffusionFunctorDirichletBC
    boundary = top
    variable = superficial_u
    functor = 0
  []
  [inlet_v]
    type = LinearFVAdvectionDiffusionFunctorDirichletBC
    boundary = top
    variable = superficial_v
    functor = -${flow_vel}
  []

  [pressure-extrapolation]
    type = LinearFVExtrapolatedPressureBC
    boundary = 'top'
    variable = pressure
    use_two_term_expansion = true
  []

  # Fix the outlet pressure and leave the outlet velocity free.
  [outlet_u]
    type = LinearFVAdvectionDiffusionOutflowBC
    boundary = bottom
    variable = superficial_u
    use_two_term_expansion = true
    assume_fully_developed_flow = true
    # assume_fully_developed_flow = true
  []
  [outlet_v]
    type = LinearFVAdvectionDiffusionOutflowBC
    boundary = bottom
    variable = superficial_v
    use_two_term_expansion = true
    assume_fully_developed_flow = true
    # assume_fully_developed_flow = true
  []
  [outlet_p]
    type = LinearFVAdvectionDiffusionFunctorDirichletBC
    boundary = bottom
    variable = pressure
    functor = ${p_out}
  []

  # Symmetry removes any wall losses and keeps the exact solution one-dimensional.
  [symmetry_u]
    type = LinearFVVelocitySymmetryBC
    boundary = 'left right'
    variable = superficial_u
    u = superficial_u
    v = superficial_v
    momentum_component = x
  []
  [symmetry_v]
    type = LinearFVVelocitySymmetryBC
    boundary = 'left right'
    variable = superficial_v
    u = superficial_u
    v = superficial_v
    momentum_component = y
  []
  [pressure_symmetric]
    type = LinearFVPressureSymmetryBC
    boundary = 'left right'
    variable = pressure
    HbyA_flux = 'HbyA'
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

[]

[Functions]
  [rho_parsed]
    type = ParsedFunction
    expression = 'if(y < 10, 2.65 + 0.11*exp(0.40*y), 8.60161)'
  []
[]

[FunctorMaterials]
  
  [fluid_props]
    type = GeneralFunctorFluidProps
    fp = fp
    pressure = pressure
    T_fluid = ${T_inlet}
    # T_fluid = T_fluid
    speed = 1
    porosity = porosity
    characteristic_length = 0.06
  []


  [porosity]
    type = PiecewiseByBlockFunctorMaterial
    prop_name = porosity
    subdomain_to_prop_value = 'bed ${bed_porosity} cavity 1'
  []

  [drag_bed]
    type = GenericVectorFunctorMaterial
    prop_names = 'bed_forch_vec'
    prop_values = '${bed_forch} ${bed_forch} ${bed_forch}'
  []

  [drag_cavity]
    type = GenericVectorFunctorMaterial
    prop_names = 'cavity_forch_vec'
    prop_values = '0 0 0'
  []

  [forch]
    type = PiecewiseByBlockVectorFunctorMaterial
    prop_name = 'Forchheimer_coefficient'
    subdomain_to_prop_value = 'bed bed_forch_vec
                              cavity cavity_forch_vec'
  []


  [fluid_enthalpy_material]
    type = LinearFVEnthalpyFunctorMaterial
    pressure = pressure
    T_fluid = T_fluid
    h = h_fluid
    fp = fp
  []

  [fluid_constants]
    type = GenericFunctorMaterial
    prop_names = 'kappa_h'
    prop_values = '${kappa_h}'
  []
[]

[AuxVariables]
  [rho_aux]
    type = MooseLinearVariableFVReal
  []
  [porosity_aux]
    type = MooseLinearVariableFVReal
  []

  [T_fluid]
    type = MooseLinearVariableFVReal
    initial_condition = ${T_inlet}
  []
[]

[AuxKernels]
  [assign_rho_aux]
    type = FunctorAux
    variable = rho_aux
    functor = 'rho_parsed'
    execute_on = 'initial timestep_end'
  []
  [assign_porosity_aux]
    type = FunctorAux
    variable = porosity_aux
    functor = 'porosity'
    execute_on = 'initial timestep_end'
  []

  [fluid_temperature]
    type = FunctorAux
    variable = T_fluid
    functor = T_from_p_h
    execute_on = NONLINEAR
  []
[]

[Postprocessors]


  # Overall pressure drop from the solved field.
  [p_top]
    type = SideAverageValue
    variable = pressure
    boundary = top
  []
  [p_bottom]
    type = SideAverageValue
    variable = pressure
    boundary = bottom
  []
  [delta_p]
    type = ParsedPostprocessor
    expression = 'p_top-p_bottom'
    pp_names = 'p_top p_bottom'
  []

  [T_outlet_avg]
    type = SideAverageValue
    variable = T_fluid
    boundary = bottom
  []
[]


[Executioner]
  type = SIMPLE
  momentum_l_abs_tol = 1e-14
  pressure_l_abs_tol = 1e-16
  momentum_l_tol = 0
  pressure_l_tol = 0
  rhie_chow_user_object = rc
  momentum_systems = 'u_system v_system'
  pressure_system = pressure_system
  momentum_equation_relaxation = 0.4
  pressure_variable_relaxation = 0.2
  num_iterations = 500
  pressure_absolute_tolerance = 1e-10
  momentum_absolute_tolerance = 1e-10
  momentum_petsc_options_iname = '-pc_type -pc_hypre_type'
  momentum_petsc_options_value = 'hypre boomeramg'
  pressure_petsc_options_iname = '-pc_type -pc_hypre_type'
  pressure_petsc_options_value = 'hypre boomeramg'
  print_fields = false
  continue_on_max_its = true

  energy_system = energy_system
  energy_l_abs_tol = 1e-12
  energy_l_tol = 0
  energy_equation_relaxation = 0.5
  energy_absolute_tolerance = 1e-8
  energy_petsc_options_iname = '-pc_type -pc_hypre_type'
  energy_petsc_options_value = 'hypre boomeramg'
[]

[Outputs]
  exodus = true
  # csv = true
  # execute_on = timestep_end
[]