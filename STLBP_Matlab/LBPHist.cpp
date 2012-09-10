#include <string.h>
#include "math.h"
#include "stdafx.h"
#include "mex.h"

#define BOUND(x, lowerbound, upperbound)  { (x) = (x) > (lowerbound) ? (x) : (lowerbound); \
    (x) = (x) < (upperbound) ? (x) : (upperbound); };
typedef unsigned char BYTE;
#define POW(nBit)   (1 << (nBit))
int  UniformPattern59[256]={    
	     1,   2,   3,   4,   5,   0,   6,   7,   8,   0,   0,   0,   9,   0,  10,  11,
		12,   0,   0,   0,   0,   0,   0,   0,  13,   0,   0,   0,  14,   0,  15,  16,
		17,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
		18,   0,   0,   0,   0,   0,   0,   0,  19,   0,   0,   0,  20,   0,  21,  22,
		23,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
		0,    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
		24,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
		25,   0,   0,   0,   0,   0,   0,   0,  26,   0,   0,   0,  27,   0,  28,  29,
		30,  31,   0,  32,   0,   0,   0,  33,   0,   0,   0,   0,   0,   0,   0,  34,
		0,    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  35,
		0,    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,
		0,    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  36,
		37,  38,   0,  39,   0,   0,   0,  40,   0,   0,   0,   0,   0,   0,   0,  41,
		0,    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,  42,
		43,  44,   0,  45,   0,   0,   0,  46,   0,   0,   0,   0,   0,   0,   0,  47,
		48,  49,   0,  50,   0,   0,   0,  51,  52,  53,   0,  54,  55,  56,  57,  58
};

float sins[8] = { 0, 0.707, 1, 0.708, 0.002, -0.706,-1, -0.709};
float coss[8] = { 1, 0.707, 0.001,-0.706,-1,-0.709,-0.002, 0.705};
void LBPHist(BYTE ***fg, int width, float **Histogram)

{
    int i,j;
    int xc,yc;			BYTE CenterByte;
    int BasicLBP = 0;	int FeaBin = 0;		int p;
    int X,Y,Z;

    width = width - 1;
    for(i = 1; i < width; i++)
    {
        for(yc = 1; yc < width; yc++)
        {
            for(xc = 1; xc < width; xc++)
            {
                CenterByte = fg[i][yc][xc];
                BasicLBP = 0;	FeaBin = 0;

                for(p = 0; p < 8; p++)
                {
                    X = int (xc + coss[p] + 0.5);
                    Y = int (yc - sins[p] + 0.5);
                    BOUND(X,0,width); BOUND(Y,0,width);
                    if(fg[i][Y][X] >= CenterByte) BasicLBP += POW ( FeaBin); 
                    FeaBin++;
                }

                Histogram[0][UniformPattern59[BasicLBP]]++;


                BasicLBP = 0;	FeaBin = 0;
                for(p = 0; p < 8; p++)
                {
                    X = int (xc + coss[p] + 0.5);
                    Z = int (i + sins[p] + 0.5);
                    BOUND(X,0,width); BOUND(Z,0,width);

                    if(fg[Z][yc][X] >= CenterByte) BasicLBP += POW ( FeaBin);
                    FeaBin++;
                }

                Histogram[1][UniformPattern59[BasicLBP]]++;

                BasicLBP = 0;	FeaBin = 0;
                for(p = 0; p < 8; p++)
                {
                    Y = int (yc - sins[p]+ 0.5);
                    Z = int (i + coss[p] + 0.5);
                    BOUND(Y,0,width); BOUND(Z,0,width);

                    if(fg[Z][Y][xc] >= CenterByte) BasicLBP += POW ( FeaBin);
                    FeaBin++;
                }

                Histogram[2][UniformPattern59[BasicLBP]]++;

            }//for(xc = BoderLength; xc < width - BoderLength; xc++)
        }//for(yc = BoderLength; yc < height - BoderLength; yc++)

    }//for(i = TimeLength; i < Length - TimeLength; i++)


    //-------------  Normalization ----------------------------//

    // Normaliztion
    int Total = 0;
    for(j = 0; j < 3; j++)
    {
        Total = 0;
        for(i = 0; i < 59; i++)  
            Total += int (Histogram[j][i]);
        for(i = 0; i < 59; i++)
        {
            Histogram[j][i] /= Total;   

        }
    }
    //-------------  Normalization ----------------------------//
}

void mexFunction( int nlhs, mxArray *plhs[],
        int nrhs, const mxArray*prhs[]) {

    int m, n, p;
    mwIndex subs[3] = {0, 0, 0};
    mwIndex frameInd = 0;
    BYTE ***image3d;


    const mwSize *dims = mxGetDimensions(prhs[0]);
    mwSize width = int(dims[1]);

    image3d = new BYTE**[width];
    BYTE *inpr = (BYTE *)mxGetData(prhs[0]);
    for(p = 0; p < width; p++) {
        image3d[p] = New2DPointer<BYTE>(width, width);
        subs[2] = p;
        frameInd = mxCalcSingleSubscript(prhs[0], 3, subs);
        for(n = 0; n < width; n++) {
            memcpy(image3d[p][n], &inpr[frameInd + n*width], width); 
        }
    }

    plhs[0] = mxCreateNumericMatrix(1, 177, mxSINGLE_CLASS, mxREAL);

    float **hist = New2DPointer<float>(3, 59);
    for(n = 0; n< 3;n++)
        memset(hist[n], 0, 236);

    LBPHist(image3d, width, hist);
    float *outpr = (float *)mxGetData(plhs[0]);
    memcpy(&outpr[0], hist[0], 236);
    memcpy(&outpr[59], hist[1], 236);
    memcpy(&outpr[108], hist[2], 236);

    Delete2DPointer(hist, 3);
    for(p = 0; p < width; p++) {
        for(n = 0; n < width; n++)
            free(image3d[p][n]);
        free(image3d[p]);
    }
    free(image3d);
}
