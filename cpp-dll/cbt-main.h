#define DLL_API extern "C" __declspec(dllexport)
#define DLL_CALLCONV __stdcall

using namespace std;

void fnOutputDebug(std::string input) {
    std::stringstream ss;
    ss << "qpv: " << input;
    OutputDebugStringA(ss.str().data());
}
