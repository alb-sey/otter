//* This file is part of the MOOSE framework
//* https://mooseframework.inl.gov
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html
#include "OtterOtter.h"
#include "OtterApp.h"
#include "Moose.h"
#include "AppFactory.h"
#include "MooseSyntax.h"

InputParameters
OtterOtter::validParams()
{
  InputParameters params = OtterApp::validParams();
  params.set<bool>("use_legacy_material_output") = false;
  params.set<bool>("use_legacy_initial_residual_evaluation_behavior") = false;
  return params;
}

OtterOtter::OtterOtter(const InputParameters & parameters) : MooseApp(parameters)
{
  OtterOtter::registerAll(
      _factory, _action_factory, _syntax, getParam<bool>("allow_test_objects"));
}

OtterOtter::~OtterOtter() {}

void
OtterOtter::registerAll(Factory & f, ActionFactory & af, Syntax & s, bool use_test_objs)
{
  OtterApp::registerAll(f, af, s);
  if (use_test_objs)
  {
    Registry::registerObjectsTo(f, {"OtterOtter"});
    Registry::registerActionsTo(af, {"OtterOtter"});
  }
}

void
OtterOtter::registerApps()
{
  registerApp(OtterApp);
  registerApp(OtterOtter);
}

/***************************************************************************************************
 *********************** Dynamic Library Entry Points - DO NOT MODIFY ******************************
 **************************************************************************************************/
// External entry point for dynamic application loading
extern "C" void
OtterOtter__registerAll(Factory & f, ActionFactory & af, Syntax & s)
{
  OtterOtter::registerAll(f, af, s);
}
extern "C" void
OtterOtter__registerApps()
{
  OtterOtter::registerApps();
}
