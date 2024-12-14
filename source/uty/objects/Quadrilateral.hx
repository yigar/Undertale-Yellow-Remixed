package uty.objects;

import flixel.util.FlxPool.IFlxPool;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxSort;

class Quad
{
    /*

	public static var pool(get, never):IFlxPool<Quad>;

	//static var _pool:FlxPool<Quad> = new FlxPool(Quad.new.bind(0, 0, 0, 0));

    //need to sort points in order so they draw the quad and not a hourglass
    //need to determine which one is top-left & so on

    //points. pointA will always be the generally most top-left, then it proceeds clockwise.
    public var pointA:FlxPoint;
    public var pointB:FlxPoint;
    public var pointC:FlxPoint;
    public var pointD:FlxPoint;

    //slopes between each connected point
    public var slopeAB(get, set):Float;
    public var slopeBC(get, set):Float;
    public var slopeCD(get, set):Float;
    public var slopeDA(get, set):Float;

    //from the top-left to bottom-right
    public var containerRect:FlxRect;

    public function new(a:Array<Float>, b:Array<Float>, c:Array<Float>, d:Array<Float>)
    {

    }

    //sorts points, as mentioned above
    public function sortPoints()
    {
        var initialOrder = [0,1,2,3]; //used for tracking the removed elements
        var order = [0,0,0,0];
        var points = [pointA, pointB, pointC, pointD];

        //point A should have the lowest overall values and be closest to the top-left.
        var pointTotals = [];
        for(point in points) {
            pointTotals.push(point.x + point.y);
        }

        //least equals the index of the lowest x+y value
        var least = 0;
        for(i in 1...pointTotals.length) { //don't check the first point, it's default
            if(pointTotals[i] < pointTotals[least])
                least = i;
        }
        order[0] = least;
        initialOrder.remove(least);

        //point B should have the lowest Y value out of the remaining points
        var leastY = (least == 0 ? 1 : 0); //default to point B if point A is already taken
        for(i in 0...points.length) {
            if(i != least && points[i].y < points[leastY].y)
                leastY = i;
        }
        order[1] = leastY;
        initialOrder.remove(leastY);

        //point C should not intersect any lines within the quad bounds
        //subtract degreesTo from each other to get the 3-point angle
        var tempOrder = [order[0], order[1], initialOrder[0], initialOrder[1]];
        //angleSet1 = FlxPoint.degreesTo(points[tempOrder[0]], points[tempOrder[1]]) - FlxPoint.degreesTo()
    }

    public function reorderPoints(order:Array<Int>)
    {
        //create a map
    }

    private function doLinesIntersect(line1A:FlxPoint, line1B:FlxPoint, line2A:FlxPoint, line2B:FlxPoint)
    {

    }

    */
}