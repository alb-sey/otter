[Mesh]
    type=GeneratedMesh # Can generate simple lines, rectangles and rectangular prisms
    dim=2 # Mesh dimension
    nx=100
    ny=10
    xmax=0.304 #Length of test chamber
    ymax=0.0257 # test chamber radius (because we are in rz axisymetric ??)
    rz_coord_axis = X 
    coord_type = RZ #r-z axisymetric
[]

[Problem]
    type = FEProblem
[]

[Variables]
    [pressure]
        # (Are there things you can add there ?)
    []
[]

[Kernels]
    [diffusion].   # (I can call this whatever I want, right ?)
        type = ADDiffusion #Laplacian operator. (He knows exactly what this means ?)
        variable = pressure
    []
[]

[BCs]
    [inlet]
        type=ADDirichletBC #BC u=value, basic
        variable = pressure
        boundary = left # (How does it know what is right and left ?)
        value =4000
    []
    [outlet]
        type=ADDirichletBC 
        variable = pressure
        boundary = right
        value =0

[Executioner]
    type=Steady #Steady state problem
    solve_type = NEWTON #newton solve

    petsc_options_iname = '-pc_type -pc_hypre_type' #(I really do not understand this)
    petsc_options_value = ' hypre    boomeramg'
[]

[Outputs]
    exodus=true #(this neither)
[]

