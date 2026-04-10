#include "TestAppApp.h"
#include "Moose.h"
#include "AppFactory.h"
#include "ModulesApp.h"
#include "MooseSyntax.h"

InputParameters
TestAppApp::validParams()
{
  InputParameters params = MooseApp::validParams();
  params.set<bool>("use_legacy_material_output") = false;
  params.set<bool>("use_legacy_initial_residual_evaluation_behavior") = false;
  return params;
}

TestAppApp::TestAppApp(const InputParameters & parameters) : MooseApp(parameters)
{
  TestAppApp::registerAll(_factory, _action_factory, _syntax);
}

TestAppApp::~TestAppApp() {}

void
TestAppApp::registerAll(Factory & f, ActionFactory & af, Syntax & syntax)
{
  ModulesApp::registerAllObjects<TestAppApp>(f, af, syntax);
  Registry::registerObjectsTo(f, {"TestAppApp"});
  Registry::registerActionsTo(af, {"TestAppApp"});

  /* register custom execute flags, action syntax, etc. here */
}

void
TestAppApp::registerApps()
{
  registerApp(TestAppApp);
}

/***************************************************************************************************
 *********************** Dynamic Library Entry Points - DO NOT MODIFY ******************************
 **************************************************************************************************/
extern "C" void
TestAppApp__registerAll(Factory & f, ActionFactory & af, Syntax & s)
{
  TestAppApp::registerAll(f, af, s);
}
extern "C" void
TestAppApp__registerApps()
{
  TestAppApp::registerApps();
}
