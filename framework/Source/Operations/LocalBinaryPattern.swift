/* This is based on "Accelerating image recognition on mobile devices using GPGPU" by Miguel Bordallo Lopez, Henri Nykanen, Jari Hannuksela, Olli Silven and Markku Vehvilainen
 http://www.ee.oulu.fi/~jhannuks/publications/SPIE2011a.pdf

 Right pixel is the most significant bit, traveling clockwise to get to the upper right, which is the least significant
 If the external pixel is greater than or equal to the center, set to 1, otherwise 0

 2 1 0
 3   7
 4 5 6

 01101101
 76543210 
*/

public class LocalBinaryPattern: TextureSamplingOperation {
    public init() {
        super.init(fragmentShader:LocalBinaryPatternFragmentShader)
    }
}