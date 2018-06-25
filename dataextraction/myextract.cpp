#include <iostream>
#include <opencv2/opencv.hpp>

using namespace std;
using namespace cv;



int main()
{
    // Load source image
    string filename = "sem21-15.jpg";
    Mat src = imread(filename);

    // Check if image is loaded fine
    if(!src.data) {
	cout << "Problem loading image!" << endl;
	return -1;
    }

    // show the original image
    namedWindow("original", WINDOW_NORMAL);
    imshow("original", src);

    //Transform source image to gray if it is not
    Mat gray;

    if (src.channels() == 3)
	cvtColor(src, gray, CV_BGR2GRAY);
	
    else
	gray = src;


     // Apply adaptiveThreshold at the bitwise_not of gray, notice the ~ symbol
    Mat bw;
    adaptiveThreshold(~gray, bw, 255, CV_ADAPTIVE_THRESH_MEAN_C, THRESH_BINARY, 15, -2);

    // Show binary image
    namedWindow("binary", WINDOW_NORMAL);
    imshow("binary", bw);


    // Create the images that will use to extract the horizonta and vertical lines
    Mat horizontal = bw.clone();
    Mat vertical = bw.clone();


        int scale = 15; // play with this variable in order to increase/decrease the amount of lines to be detected

    // Specify size on horizontal axis
    int horizontalsize = horizontal.cols / scale;

    // Create structure element for extracting horizontal lines through morphology operations
    Mat horizontalStructure = getStructuringElement(MORPH_RECT, Size(horizontalsize,1));

        // Apply morphology operations
    erode(horizontal, horizontal, horizontalStructure, Point(-1, -1));
    dilate(horizontal, horizontal, horizontalStructure, Point(-1, -1));
    //    dilate(horizontal, horizontal, horizontalStructure, Point(-1, -1)); // expand horizontal lines

    // Show extracted horizontal lines
    namedWindow("horizontal", WINDOW_NORMAL);
    imshow("horizontal", horizontal);

        
    waitKey(0);
    return 0;
}
