#include "OtterApp.h"
#include "Moose.h"
#include "AppFactory.h"
#include "ModulesApp.h"
#include "MooseSyntax.h"

InputParameters
OtterApp::validParams()
{
  InputParameters params = MooseApp::validParams();
  params.set<bool>("use_legacy_material_output") = false;
  params.set<bool>("use_legacy_initial_residual_evaluation_behavior") = false;
  return params;
}

OtterApp::OtterApp(const InputParameters & parameters) : MooseApp(parameters)
{
  OtterApp::registerAll(_factory, _action_factory, _syntax);
}

OtterApp::~OtterApp() {}

void
OtterApp::registerAll(Factory & f, ActionFactory & af, Syntax & syntax)
{
  ModulesApp::registerAllObjects<OtterApp>(f, af, syntax);
  Registry::registerObjectsTo(f, {"OtterApp"});
  Registry::registerActionsTo(af, {"OtterApp"});

  /* register custom execute flags, action syntax, etc. here */
}

void
OtterApp::registerApps()
{
  registerApp(OtterApp);
}

/***************************************************************************************************
 *********************** Dynamic Library Entry Points - DO NOT MODIFY ******************************
 **************************************************************************************************/
extern "C" void
OtterApp__registerAll(Factory & f, ActionFactory & af, Syntax & s)
{
  OtterApp::registerAll(f, af, s);
}
extern "C" void
OtterApp__registerApps()
{
  OtterApp::registerApps();
}
