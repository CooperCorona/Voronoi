//
//  ColorGraph.swift
//  Voronoi
//
//  Created by Cooper Knaak on 1/30/19.
//

import Foundation
import CoronaErrors

///Maps instances a given type to their corresponding colors.
public typealias ColorAssignment<T> = [T:Int] where T: Hashable

///A simple undirected, unweighted graph structure implementing Kempe's algorithm
///to assign "colors" (represented as ints) to each node such that no adjacent
///nodes are assigned the same color.
internal class ColorGraph<T: Hashable> {

    ///A function generating a random number in the closed range 0..<$0.
    private typealias Random = (Int) -> Int

    ///The graph's nodes. Must be a dictionary rather than a set because
    ///the algorithm only works if the same ColorNode instances are used
    ///for the same underlying values, but there's no `O(1)` method to
    ///extract a value from a Set.
    private var nodes:[T:ColorNode<T>] = [:]
    ///Maps a node to the set of nodes it has an edge between (is adjacent to).
    private var adjacencyList:[ColorNode<T>:Set<ColorNode<T>>] = [:]

    ///Initializes a graph with no nodes or edges.
    internal init() {

    }

    ///Initializes a graph with the given nodes.
    internal init<U: Sequence>(nodes:U) where U.Element == T {
        self.nodes = Dictionary<T, ColorNode<T>>(uniqueKeysWithValues: nodes.map() { ($0, ColorNode(value: $0)) })
    }

    ///Adds a node to the graph. Does nothing if the node already exists.
    internal func add(node:T) {
        let n = ColorNode(value: node)
        self.nodes[node] = n
        self.adjacencyList[n] = Set<ColorNode<T>>()
    }

    ///Adds an edge between `from` and `to`. If either `from` or `to` does not exist,
    ///throws a `ValueException`.
    internal func addEdge(from:T, to:T) throws {
        guard let fromNode = self.nodes[from] else {
            throw ValueException(error: ValueError.invalidArgument, message: "ColorGraph does not contain from node \(from)", actualValue: from)
        }
        guard let toNode = self.nodes[to] else {
            throw ValueException(error: ValueError.invalidArgument, message: "ColorGraph does not contain to node \(to)", actualValue: to)
        }
        self.adjacencyList[fromNode]?.insert(toNode)
        self.adjacencyList[toNode]?.insert(fromNode)
    }

    ///Returns a graph without the given node (removing edges containing
    ///that node as appropriate). Returns a copy of this graph if
    ///the given node is not in the graph.
    internal func graph(without node:T) throws -> ColorGraph<T> {
        let removedNode = self.nodes[node]!
        let graph = ColorGraph<T>()
        graph.nodes = self.nodes
        graph.nodes[node] = nil
        graph.adjacencyList = self.adjacencyList
        graph.adjacencyList[removedNode] = nil
        for (_, remainingNode) in graph.nodes {
            graph.adjacencyList[remainingNode]?.remove(removedNode)
        }
        return graph
    }

    ///Returns the degree of the given node (the number of edges it has).
    private func degree(of node:ColorNode<T>) -> Int {
        return self.adjacencyList[node]!.count
    }

    ///Returns a function used to generate random colors.
    private func randomGenerator() -> Random  {
        //Because the parameter is an Int, the reuslting value
        //must be in Int's domain, so it is safe to cast it back.
        return { (n:Int) in Int(arc4random_uniform(UInt32(n))) }
    }

    ///Assigns a color to `node` that is assigned to none of its neighbors.
    ///If `count` is too low (`<= 5` for an untiled diagram, `<= 10` for a
    ///tiled diagram), then it is possible that two adjacent nodes share a
    ///color (due to the Pigeonhole Principle).
    private func color(for node:ColorNode<T>, count:Int, rand:Random) -> Int {
        let usedColors = Set(self.adjacencyList[node]!.map() { $0.color })
        let n = count - self.degree(of: node)
        let index = rand(n)
        var i = 0
        while usedColors.contains(i) {
            i += 1
        }
        for _ in 0..<index {
            i += 1
            while usedColors.contains(i) {
                i += 1
            }
        }
        //If there are not enough colors to completely color a graph (6 for a plane,
        //10+ for a torus), then it is possible all colors have been used by a node's
        //neighbors. A color is randomly chosen, since it is impossible to perfectly
        //color the graph.
        guard i < count else {
            return rand(count)
        }
        return i
    }

    ///Recursively removes the lowest degree node from the graph, gets the subgraph's
    ///color assignment, and colors the node.
    /// - parameter count: The number of distinct states `color` can be.
    /// - parameter rand: A function generating a random color between 0 and `count`.
    private func _colorGraph(count:Int, rand:Random) -> ColorAssignment<T> {
        guard self.nodes.count > 1 else {
            guard let (_, node) = self.nodes.first else {
                return [:]
            }
            let color = rand(count)
            node.color = color
            return [node.value:color]
        }
        let minimumNode = self.nodes.min() { self.degree(of: $0.value) < self.degree(of: $1.value) }!.value
        let subGraph = try! self.graph(without: minimumNode.value)
        var colorAssignment = subGraph._colorGraph(count: count, rand: rand)
        let color = self.color(for: minimumNode, count: count, rand: rand)
        minimumNode.color = color
        colorAssignment[minimumNode.value] = color
        return colorAssignment
    }

    ///Assigns a color to each node in this graph such that no two adjacent nodes
    ///share the same color (if `count` is high enough).
    /// - parameter count: The number of distinct states `color` can be.
    /// - parameter random: A random number generator used to randomly assign colors.
    internal func colorGraph(count:Int) -> ColorAssignment<T> {
        let rand = self.randomGenerator()
        return self._colorGraph(count: count, rand: rand)
    }

}
