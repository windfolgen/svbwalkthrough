#include <vector>
#include <complex>
#include <algorithm>
#include <cmath>
using C=std::complex<double>;
// Coefficients of a triangular dlog system. At the origin the polynomial variable is log(t).
extern "C" void advance(int nw,int order,int origin,double logstep,const int *offset,const int *child,
                        const int *kern,const int *weight,const C *poles,const C *y0,C *out) {
    const int logs=origin?9:1, width=(order+1)*logs;
    std::vector<C> jets(static_cast<size_t>(nw)*width),force(width);
    for(int i=0;i<nw;i++){
        std::fill(force.begin(),force.end(),C(0));
        for(int e=offset[i];e<offset[i+1];++e){
            const C *s=jets.data()+static_cast<size_t>(child[e])*width;
            const C *d=poles+kern[e]*(order+1);
            for(int j=0;j<=order;j++){
                C v=d[j]*static_cast<double>(weight[e]);
                if(v==C(0)) continue;
                for(int k=j*logs;k<width;k++) force[k]+=v*s[k-j*logs];
            }
        }
        C *a=jets.data()+static_cast<size_t>(i)*width;
        a[0]=y0[i];
        for(int l=1;l<logs;l++) a[l]=force[l-1]/static_cast<double>(l);
        for(int n=1;n<=order;n++)
            for(int l=logs-1;l>=0;l--)
                a[n*logs+l]=(force[n*logs+l]-(l+1<logs?static_cast<double>(l+1)*a[n*logs+l+1]:C(0)))/static_cast<double>(n);
        C value=0;
        for(int l=logs-1;l>=0;l--){
            C v=0;for(int n=0;n<=order;n++) v+=a[n*logs+l];
            value=value*logstep+v;
        }
        out[i]=value;
    }
}
