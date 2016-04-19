/*=================================================================
 *
 * DDDM ALGORITHM FOR ESTIMATION OF POSTERIORS, ETC IN HMM
 *
 */

#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include "mex.h"
#include "matrix.h"

/*Bayesian_approx(metaH,pH0pr,Hpr,l1pr,l2pr,musgnpr,pHmatpr,q1matpr,q2matpr,N,M);*/

void particle_filter_learnH_learnsigma(
        double metaH,
        double *H0pr,
        int H0len,
        double *xpr,
        double *musgnpr,
        double *q1samp_pr,
        double *q2samp_pr,
        double *Hsamp_pr,
        double *sigma2_pr,
        int N,
        double partM,
        int simN,
        double sigma0,
        double N0,
        double mu,
        double *etapr,
        double etalen
        )
        
{
    
    int n, m, musgn, cp, musgnext, found, randm, simn;
    double LLR, eta, x, *partHpr, *q1currpr, *q2currpr, H, q1samp, q2samp, *wpr, w, l1, l2, cumw, randval, SS, sigma2, F;

    for (simn = 0; simn < simN; simn++) {
        
        partHpr = mxGetPr(mxCreateDoubleMatrix(partM, 1, mxREAL));
        q1currpr = mxGetPr(mxCreateDoubleMatrix(partM, 1, mxREAL));
        q2currpr = mxGetPr(mxCreateDoubleMatrix(partM, 1, mxREAL));
        
        wpr = mxGetPr(mxCreateDoubleMatrix(partM, 1, mxREAL));

        sigma2 = pow(sigma0,2);
        SS = N0 * sigma2;
      
        q1samp = .5;
        q2samp = .5;
        
        for (m=0; m<partM; m++) {
            randm = H0len * (double)rand() / (double)((unsigned)RAND_MAX + 1);
            *(partHpr+m) = *(H0pr+randm);
        }
        
        for (n = 0; n < N; n++) {
            
            F = sigma2 / mu;
            x = *(xpr+n);
            randm = etalen * (double)rand() / (double)((unsigned)RAND_MAX + 1);
            eta = *(etapr+randm);
            x += eta;
            
            LLR = x/F;
            
            l1 = 1/(1+exp(-LLR));
            l2 = 1-l1;
            
            musgn = *(musgnpr+n);
            
            switch (musgn) {
                case 0:
                    for (m=0; m<partM; m++) {
                        H = *(partHpr+m);
                        *(q1currpr+m) = l1*((1-H) * q1samp + H * q2samp);
                        *(q2currpr+m) = l2*(H * q1samp + (1-H) * q2samp);
                    }
                    break;
                    
                case 1:
                    for (m=0; m<partM; m++) {
                        H = *(partHpr+m);
                        *(q1currpr+m) = l1*(1-H);
                        *(q2currpr+m) = l2*H;
                    }
                    break;
                    
                case -1:
                    for (m=0; m<partM; m++) {
                        H = *(partHpr+m);
                        *(q1currpr+m) = l1*H;
                        *(q2currpr+m) = l2*(1-H);
                    }
                    break;
                    
            }
            
            w = 0;
            
            for (m=0; m<partM; m++) {
                *(wpr+m) = *(q1currpr+m) + *(q2currpr+m);
                w+=*(wpr+m);
            }
            
            cumw=0;
            found=0;
            randm = 0;
            randval = (double)rand() / (double)((unsigned)RAND_MAX + 1);
            
            while (found==0 & randm<partM) {
                cumw+=*(wpr+randm)/w;
                found = cumw>randval?1:0;
                randm++;
            }
            
            q1samp = *(q1currpr+randm-1) / *(wpr+randm-1);
            q2samp = *(q2currpr+randm-1) / *(wpr+randm-1);
            
            *(q1samp_pr+simn+simN*n) = q1samp;
            *(q2samp_pr+simn+simN*n) = q2samp;
            *(Hsamp_pr+simn+simN*n) = *(partHpr+randm-1);
            
            cp = -1;
            if (n<N) {
                musgnext = *(musgnpr+n+1);
                
                if (musgn!=0 & musgnext!=0 & musgn==musgnext) {
                    cp = 0;
                }
                else if (musgn!=0 & musgnext!=0 & musgn!=musgnext) {
                    cp = 1;
                }
                
                /* update sigma estimate */
                
                switch (musgnext) {
                    
                    case 0:
                        SS += q1samp * pow((x - mu/2),2) + q2samp * pow((x + mu/2),2);
                        break;
                        
                    case -1:
                        SS += pow((x + mu/2),2);
                        break;
                        
                    case 1:
                        SS += pow((x - mu/2),2);
                        break;
                        
                }
                
            }
            
            else {
                
                SS += q1samp * pow((x - mu/2),2) + q2samp * pow((x + mu/2),2);
                
            }

            sigma2 = SS / (N0+n+1);
            *(sigma2_pr+simn+simN*n) = sigma2;

            /* determine new weights if there was feedback */
            
            switch (cp) {
                case 0:
                    w = 0;
                    for (m=0; m<partM; m++) {
                        H = *(partHpr+m);
                        *(wpr+m) = (1-H);
                        w += *(wpr+m);
                    }
                    break;
                    
                case 1:
                    w = 0;
                    for (m=0; m<partM; m++) {
                        H = *(partHpr+m);
                        *(wpr+m) = H;
                        w += *(wpr+m);
                    }
                    break;
                    
            }
            
            /* update particles */

            
            
            for (m=0; m<partM; m++) {
                randval = (double)rand() / (double)((unsigned)RAND_MAX + 1);
                
                if (randval<metaH){
                    randm = H0len * (double)rand() / (double)((unsigned)RAND_MAX + 1);
                    *(partHpr+m) = *(H0pr+randm);
                    
                }
                
                else {
                    
                    cumw=0;
                    found=0;
                    randm = 0;
                    
                    while (found==0 & randm<partM) {
                        cumw+=*(wpr+randm)/w;
                        found = cumw>randval?1:0;
                        randm++;
                    }
                    
                    *(partHpr+m) = *(partHpr+randm-1);
                    
                }
            }
             
             

            
        }
        
    }
    
}


void mexFunction( int nlhs, mxArray*plhs[],
        int nrhs, const mxArray*prhs[])
        
        /* VARIABLES ARE N, LPr, H, H0, alpha, J, H */
        
        
{
    double F, metaH, *H0pr, *xpr, *musgnpr, *q1samp_pr, *q2samp_pr, *Hsamp_pr, partM, *etapr, etalen, *sigma2_pr, mu, N0, sigma0;
    int N, Hlen, simN;
    
    metaH = mxGetScalar(prhs[0]);
    H0pr = mxGetPr(prhs[1]);
    sigma0 = mxGetScalar(prhs[2]);
    N0 = mxGetScalar(prhs[3]);
    mu = mxGetScalar(prhs[4]);
    xpr = mxGetPr(prhs[5]);
    musgnpr = mxGetPr(prhs[6]);
    partM = mxGetScalar(prhs[7]);
    simN = mxGetScalar(prhs[8]);
    etapr = mxGetPr(prhs[9]);
    
    N = mxGetM(prhs[5]);
    Hlen = mxGetM(prhs[1]);
    etalen = mxGetM(prhs[9]);
    
    plhs[0] = mxCreateDoubleMatrix(simN, N, mxREAL);
    plhs[1] = mxCreateDoubleMatrix(simN, N, mxREAL);
    plhs[2] = mxCreateDoubleMatrix(simN, N, mxREAL);
    plhs[3] = mxCreateDoubleMatrix(simN, N, mxREAL);
    
    q1samp_pr = mxGetPr(plhs[0]);
    q2samp_pr = mxGetPr(plhs[1]);
    Hsamp_pr = mxGetPr(plhs[2]);
    sigma2_pr = mxGetPr(plhs[3]);
    
    /* Do the actual computations in a subroutine */
    particle_filter_learnH_learnsigma(metaH,H0pr,Hlen,xpr,musgnpr,q1samp_pr,q2samp_pr,Hsamp_pr,sigma2_pr,N,partM,simN,sigma0,N0,mu,etapr,etalen);
    
    
}


