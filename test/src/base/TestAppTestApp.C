//* This file is part of the MOOSE framework
//* https://mooseframework.inl.gov
//*
//* All rights reserved, see COPYRIGHT for full restrictions
//* https://github.com/idaholab/moose/blob/master/COPYRIGHT
//*
//* Licensed under LGPL 2.1, please see LICENSE for details
//* https://www.gnu.org/licenses/lgpl-2.1.html
#include "TestAppTestApp.h"
#include "TestAppApp.h"
#include "Moose.h"
#include "AppFactory.h"
#include "MooseSyntax.h"

InputParameters
TestAppTestApp::validParams()
{
  InputParameters params = TestAppApp::validParams();
  params.set<bool>("use_legacy_material_output") = false;
  params.set<bool>("use_legacy_initial_residual_evaluation_behavior") = false;
  return params;
}

TestAppTestApp::TestAppTestApp(const InputParameters & parameters) : MooseApp(parameters)
{
  TestAppTestApp::registerAll(
      _factory, _action_factory, _syntax, getParam<bool>("allow_test_objects"));
}

TestAppTestApp::~TestAppTestApp() {}

void
TestAppTestApp::registerAll(Factory & f, ActionFactory & af, Syntax & s, bool use_test_objs)
{
  TestAppApp::registerAll(f, af, s);
  if (use_test_objs)
  {
    Registry::registerObjectsTo(f, {"TestAppTestApp"});
    Registry::registerActionsTo(af, {"TestAppTestApp"});
  }
}

void
TestAppTestApp::registerApps()
{
  registerApp(TestAppApp);
  registerApp(TestAppTestApp);
}

/***************************************************************************************************
 *********************** Dynamic Library Entry Points - DO NOT MODIFY ******************************
 **************************************************************************************************/
// External entry point for dynamic application loading
extern "C" void
TestAppTestApp__registerAll(Factory & f, ActionFactory & af, Syntax & s)
{
  TestAppTestApp::registerAll(f, af, s);
}
extern "C" void
TestAppTestApp__registerApps()
{
  TestAppTestApp::registerApps();
}
