#include <cstdio>
#include <ctime>
#include "MoonELP.cpp"
int main(){
  double l,b,d,s=0; const int N=20000;
  clock_t t0=clock();
  for(int i=0;i<N;i++){ elp::moonPosition(0.25 + i*1e-7, l,b,d); s+=l+b+d; }
  double us=(double)(clock()-t0)/CLOCKS_PER_SEC/N*1e6;
  printf("elp::moonPosition  %.2f us/call   (sink %.3f)\n", us, s/N);
  return 0;
}
