rho = 1

[Mesh]
  [gen]
    type = CartesianMeshGenerator
    dim=2
    dx='1 1 1 1'
    dy='1'
    ix='100 100 100 100'
    iy='20'
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
    u = superficial_vel_x
    v = superficial_vel_y
    pressure = pressure
    porosity = porosity
  []
[]

[Variables]
  [superficial_vel_x]
    type = PINSFVSuperficialVelocityVariable
    initial_condition = 1
  []
  [superficial_vel_y]
    type = PINSFVSuperficialVelocityVariable
    initial_condition = 1e-6
  []
  [pressure]
    type = BernoulliPressureVariable
    u=superficial_vel_x
    v=superficial_vel_y
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
    value=0.3
    block='3'
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
    variable = superficial_vel_x
    rho = ${rho}
    porosity = porosity
    momentum_component = 'x'
  []
  [u_pressure]
    type = PINSFVMomentumPressure
    variable = superficial_vel_x
    momentum_component = 'x'
    pressure = pressure
    porosity = porosity
  []

  [v_advection]
    type = PINSFVMomentumAdvection
    variable = superficial_vel_y
    rho = ${rho}
    porosity = porosity
    momentum_component = 'y'
  []

  [v_pressure]
    type = PINSFVMomentumPressure
    variable = superficial_vel_y
    momentum_component = 'y'
    pressure = pressure
    porosity = porosity
  []

[]

[FVBCs]
  # Select desired boundary conditions
  active = 'inlet-u inlet-v outlet-p no-slip-u no-slip-v'

  # Possible inlet boundary conditions
  [inlet-u]
    type = INSFVInletVelocityBC
    boundary = 'left'
    variable = superficial_vel_x
    functor = '1'
  []
  [inlet-v]
    type = INSFVInletVelocityBC
    boundary = 'left'
    variable = superficial_vel_y
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
    variable = superficial_vel_x
    momentum_component = 'x'
  []
  [free-slip-v]
    type = INSFVNaturalFreeSlipBC
    boundary = 'top bottom'
    variable = superficial_vel_y
    momentum_component = 'y'
  []
  [no-slip-u]
    type = INSFVNoSlipWallBC
    boundary = 'top bottom'
    variable = superficial_vel_x
    function = 0
  []
  [no-slip-v]
    type = INSFVNoSlipWallBC
    boundary = 'top bottom'
    variable = superficial_vel_y
    function = 0
  []
  [symmetry-u]
    type = PINSFVSymmetryVelocityBC
    boundary = 'bottom'
    variable = superficial_vel_x
    u = superficial_vel_x
    v = superficial_vel_y
    momentum_component = 'x'
  []
  [symmetry-v]
    type = PINSFVSymmetryVelocityBC
    boundary = 'bottom'
    variable = superficial_vel_y
    u = superficial_vel_x
    v = superficial_vel_y
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
    u = superficial_vel_x
    v = superficial_vel_y
    rho = ${rho}
  []
  [outlet-u]
    type = PINSFVMomentumAdvectionOutflowBC
    boundary = 'right'
    variable = superficial_vel_x
    u = superficial_vel_x
    v = superficial_vel_y
    porosity = porosity
    momentum_component = 'x'
    rho = ${rho}
  []
  [outlet-v]
    type = PINSFVMomentumAdvectionOutflowBC
    boundary = 'right'
    variable = superficial_vel_y
    u = superficial_vel_x
    v = superficial_vel_y
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

# Some basic Postprocessors to visually examine the solution
[Postprocessors]
  [inlet-p]
    type = SideAverageValue
    variable = 'pressure'
    boundary = 'left'
  []
  [outlet-u]
    type = SideIntegralVariablePostprocessor
    variable = 'superficial_vel_x'
    boundary = 'right'
  []
[]

[Outputs]
  exodus = true
[]
