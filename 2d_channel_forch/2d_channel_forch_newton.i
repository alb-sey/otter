rho = 1000

[Mesh]
  [gen]
    type = CartesianMeshGenerator
    dim = 2
    dx = '1 1 1 1'
    dy = '1'
    ix = '320 320 320 320'
    iy = '50'
    subdomain_id = '1 2 3 4'
  []
[]


[GlobalParams]
  rhie_chow_user_object = 'rc'
  # porosity=porosity
[]

[UserObjects]
  [rc]
    type = PINSFVRhieChowInterpolator
    u = superficial_u
    v = superficial_v
    pressure = pressure
    porosity = porosity
  []
[]

[Variables]
  [superficial_u]
    type = PINSFVSuperficialVelocityVariable
    initial_condition = 1
  []
  [superficial_v]
    type = PINSFVSuperficialVelocityVariable
    initial_condition = 1e-6
  []
  [pressure]
    type = BernoulliPressureVariable
    u=superficial_u
    v=superficial_v
    porosity=porosity
    rho=${rho}
  []
[]

[AuxVariables]
  [porosity]
    type=PiecewiseConstantVariable
  []
[]

[ICs]
  [p1]
    type=ConstantIC
    variable=porosity
    value=1
    block='1 4'
  []

  [p2]
    type=ConstantIC
    variable=porosity
    value=0.5
    block='2'
  []

  [p3]
    type=ConstantIC
    variable=porosity
    value=0.33333
    block='3'
  []
[]

[FunctorMaterials]
  [forch_zero]
    type = GenericVectorFunctorMaterial
    prop_names = 'forch_null'
    prop_values = '0 0 0'
  []

  [forch_block_2]
    type = GenericVectorFunctorMaterial
    prop_names = 'forch_2'
    prop_values = '5 5 5' #multiply by 2/porosity to get the same value as SIMPLE
  []

  [forch_block_3]
    type = GenericVectorFunctorMaterial
    prop_names = 'forch_3'
    prop_values = '1 1 1'
  []

  [forch]
    type = PiecewiseByBlockVectorFunctorMaterial
    prop_name = 'forch'
    subdomain_to_prop_value = '1 forch_null 2 forch_2 3 forch_3 4 forch_null'
  []
[]

[FVKernels]
  [mass]
    type = PINSFVMassAdvection
    variable = pressure
    rho = ${rho}
  []

  [u_advection]
    type = PINSFVMomentumAdvection
    variable = superficial_u
    rho = ${rho}
    porosity = porosity
    momentum_component = 'x'
  []
  [u_pressure]
    type = PINSFVMomentumPressure
    variable = superficial_u
    momentum_component = 'x'
    pressure = pressure
    porosity = porosity
  []

  [v_advection]
    type = PINSFVMomentumAdvection
    variable = superficial_v
    rho = ${rho}
    porosity = porosity
    momentum_component = 'y'
  []

  [v_pressure]
    type = PINSFVMomentumPressure
    variable = superficial_v
    momentum_component = 'y'
    pressure = pressure
    porosity = porosity
  []

  [u_friction]
    type = PINSFVMomentumFriction
    standard_friction_formulation=true
    rhie_chow_user_object = 'rc'
    variable = superficial_u
    Forchheimer_name = forch
    porosity = porosity
    rho = ${rho}
    u = superficial_u
    v = superficial_v
    momentum_component = 'x'
    block = '2 3'
  []
  [v_friction]
    type = PINSFVMomentumFriction
    standard_friction_formulation=true
    rhie_chow_user_object = 'rc'
    variable = superficial_v
    Forchheimer_name = forch
    porosity = porosity
    rho = ${rho}
    u = superficial_u
    v = superficial_v
    momentum_component = 'y'
    block = '2 3'
  []

[]

[FVBCs]
  # Select desired boundary conditions
  active = 'inlet-u inlet-v outlet-p no-slip-u no-slip-v'

  # Possible inlet boundary conditions
  [inlet-u]
    type = INSFVInletVelocityBC
    boundary = 'left'
    variable = superficial_u
    functor = '1'
  []
  [inlet-v]
    type = INSFVInletVelocityBC
    boundary = 'left'
    variable = superficial_v
    functor = 0
  []
  [inlet-p]
    type = INSFVOutletPressureBC
    boundary = 'left'
    variable = pressure
    function = 1
  []

  # Possible wall boundary conditions
  [free-slip-u]
    type = INSFVNaturalFreeSlipBC
    boundary = 'top bottom'
    variable = superficial_u
    momentum_component = 'x'
  []
  [free-slip-v]
    type = INSFVNaturalFreeSlipBC
    boundary = 'top bottom'
    variable = superficial_v
    momentum_component = 'y'
  []
  [no-slip-u]
    type = INSFVNoSlipWallBC
    boundary = 'top bottom'
    variable = superficial_u
    function = 0
  []
  [no-slip-v]
    type = INSFVNoSlipWallBC
    boundary = 'top bottom'
    variable = superficial_v
    function = 0
  []
  [symmetry-u]
    type = PINSFVSymmetryVelocityBC
    boundary = 'bottom'
    variable = superficial_u
    u = superficial_u
    v = superficial_v
    momentum_component = 'x'
  []
  [symmetry-v]
    type = PINSFVSymmetryVelocityBC
    boundary = 'bottom'
    variable = superficial_v
    u = superficial_u
    v = superficial_v
    momentum_component = 'y'
  []
  [symmetry-p]
    type = INSFVSymmetryPressureBC
    boundary = 'bottom'
    variable = pressure
  []

  # Possible outlet boundary conditions
  [outlet-p]
    type = INSFVOutletPressureBC
    boundary = 'right'
    variable = pressure
    function = 0
  []
  [outlet-p-novalue]
    type = INSFVMassAdvectionOutflowBC
    boundary = 'right'
    variable = pressure
    u = superficial_u
    v = superficial_v
    rho = ${rho}
  []
  [outlet-u]
    type = PINSFVMomentumAdvectionOutflowBC
    boundary = 'right'
    variable = superficial_u
    u = superficial_u
    v = superficial_v
    porosity = porosity
    momentum_component = 'x'
    rho = ${rho}
  []
  [outlet-v]
    type = PINSFVMomentumAdvectionOutflowBC
    boundary = 'right'
    variable = superficial_v
    u = superficial_u
    v = superficial_v
    porosity = porosity
    momentum_component = 'y'
    rho = ${rho}
  []
[]

[Executioner]
  type = Steady
  solve_type = 'NEWTON'

  # petsc_options_iname = '-pc_type -ksp_gmres_restart -sub_pc_type -sub_pc_factor_shift_type'
  # petsc_options_value = 'asm      300                lu           NONZERO'
  
  petsc_options_iname = '-pc_type -pc_factor_shift_type'
  petsc_options_value = ' lu       NONZERO'
  line_search = 'none'
  nl_rel_tol = 1e-8
  nl_abs_tol = 1e-8
[]


[VectorPostprocessors]
  [u_line]
    type = LineValueSampler
    variable = superficial_u
    start_point = '0 0.5 0'
    end_point = '4 0.5 0'
    num_points = 401
    sort_by = id
  []
  [p_line]
    type = LineValueSampler
    variable = pressure
    start_point = '0 0.5 0'
    end_point = '4 0.5 0'
    num_points = 401
    sort_by = id
  []
[]



# Some basic Postprocessors to visually examine the solution
[Postprocessors]
  [inlet-p]
    type = SideAverageValue
    variable = 'pressure'
    boundary = 'left'
  []
  [outlet-u]
    type = SideIntegralVariablePostprocessor
    variable = 'superficial_u'
    boundary = 'right'
  []
[]

[Outputs]
  exodus = true
  csv = true
  execute_on = 'timestep_end'
[]
