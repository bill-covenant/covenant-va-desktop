#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  // Get the actual screen resolution
  int screenWidth = ::GetSystemMetrics(SM_CXSCREEN);
  int screenHeight = ::GetSystemMetrics(SM_CYSCREEN);

  // Use 90% of the screen, capped at 1920x1080
  int windowWidth = static_cast<int>(screenWidth * 0.9);
  if (windowWidth > 1920) windowWidth = 1920;
  int windowHeight = static_cast<int>(screenHeight * 0.9);
  if (windowHeight > 1080) windowHeight = 1080;

  // Center the window on screen
  int originX = (screenWidth - windowWidth) / 2;
  int originY = (screenHeight - windowHeight) / 2;

  FlutterWindow window(project);
  Win32Window::Point origin(originX, originY);
  Win32Window::Size size(windowWidth, windowHeight);
  if (!window.Create(L"CVA Desktop", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}