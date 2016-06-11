# Voronoi
Swift framework for calculating voronoi diagrams using Fortune's Algorithm.

Use the ```VoronoiDiagram``` class to calculate the cells of a voronoi diagram. Voronoi diagrams are the edges that bisect
the lines between given points. Each point within a cell is closer to that cell's voronoi point than any other voronoi point.
Points lying on the edges of two cells are equidistant to the two voronoi points.

## Fortune's Algorithm
Fortune's Algorithm is a way of solving voronoi diagrams in ```O(n log(n))``` time. It only needs to process an event at
each voronoi point and at possible circles formed by three voronoi points (which occurs in ```O(n)``` time), and also needs
to search a binary tree at each site event (which occurs in ```O(log(n))``` time).

Fortune's algorithm uses a beach line (a piecewise curve formed by the minimum value of parabolas 
at a given x-coordinate) and a sweep line (a horizontal line corresponding to the directrix's of the parabolas). Each
voronoi point corresponds to the focus of a parabola and the sweep line corresponds to the directrix.

A parabola can be defined as a focus (a point) and a directrix (a line). The distance between any point on the parabola and its
focus is equal to the distance between that same point and the directrix (which, given that the directrix is a horizontal line,
is just the difference in y-coordinates). For example, suppose our parabola has focus
```(x, y) = (0, 1)``` and directrix ```y = -1```. ```(1, 0.25)``` lies on the parabola. The distance between the focus and that
point is ```sqrt((0 - 1)^2 + (1 - 0.25)^2) = sqrt(1 + 0.5625) = sqrt(1.5625) = 1.25``` and the distance between the point
and the directrix is ```0.25 - (-1) = 1.25```, which is the same.

Since the distance between a point and the focus and that same point and the directrix is the same, the intersection of
two parabolas with the same directrix (the sweep line) forms the bisector between those two points. By adding new parabolas
to the beach line (and splitting the previous parabolas) at every new voronoi point, Fortune's algorithm traces the edges
of the voronoi diagram.

The final consideration is circle events. When three focii all lie on the same circle, that means all three parabolas will
intersect when the sweep line reaches the top of the circle, which means the middle parabola is "squeezed" out of the beach
line. Thus, when we add or remove parabolas from the beach line, we check if they form circle events. A circle event is also
where two edges meet and a new one begins.

Once all events are processed (and incomplete edges are extended to the boundaries), the voronoi diagram is complete.

### To-Dos:
* Add images of completed voronoi diagrams.
