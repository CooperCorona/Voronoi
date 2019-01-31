//
//  ColorGraph.swift
//  Voronoi
//
//  Created by Cooper Knaak on 1/30/19.
//

import Foundation
import CoronaErrors

public typealias ColorAssignment<T> = [T:Int] where T: Hashable

internal class Node<T: Hashable>: Hashable {
    internal let value:T
    internal var color:Int = -1

    internal func hash(into hasher: inout Hasher) {
        self.value.hash(into: &hasher)
    }

    internal init(value:T) {
        self.value = value
    }
}

internal func ==<T>(lhs:Node<T>, rhs:Node<T>) -> Bool {
    return lhs.value == rhs.value
}

internal class ColorGraph<T: Hashable> {

    private typealias Random = (Int) -> Int

    private var nodes:Set<Node<T>> = []
    private var adjacencyList:[Node<T>:Set<Node<T>>] = [:]

    internal init() {

    }

    internal init<U: Sequence>(nodes:U) where U.Element == T {
        self.nodes = Set(nodes.map() { Node(value: $0) })
    }

    internal func add(node:T) {
        let n = Node(value: node)
        self.nodes.insert(n)
        self.adjacencyList[n] = Set<Node<T>>()
    }

    internal func addEdge(from:T, to:T) throws {
        let fromNode = Node(value: from)
        let toNode = Node(value: to)
        guard self.nodes.contains(fromNode) else {
            throw ValueException(error: ValueError.invalidArgument, message: "ColorGraph does not contain from node \(from)", actualValue: from)
        }
        guard self.nodes.contains(toNode) else {
            throw ValueException(error: ValueError.invalidArgument, message: "ColorGraph does not contain to node \(to)", actualValue: to)
        }
        self.adjacencyList[fromNode]?.insert(toNode)
        self.adjacencyList[toNode]?.insert(toNode)
    }

    internal func graph(without node:T) throws -> ColorGraph<T> {
        let removedNode = Node(value: node)
        let graph = ColorGraph<T>()
        graph.nodes = self.nodes
        graph.nodes.remove(removedNode)
        graph.adjacencyList = self.adjacencyList
        graph.adjacencyList[removedNode] = nil
        for remainingNode in graph.nodes {
            graph.adjacencyList[remainingNode]?.remove(removedNode)
        }
        return graph
    }

    private func degree(of node:Node<T>) -> Int {
        return self.adjacencyList[node]!.count
    }

    private func randomGenerator<R: RandomNumberGenerator>(using random:R?) -> Random  {
        let rand:Random
        if var random = random {
            rand = { (n:Int) in Int.random(in: 0..<n, using: &random) }
        } else {
            var systemRand = SystemRandomNumberGenerator()
            rand = { (n:Int) in Int.random(in: 0..<n, using: &systemRand) }
        }
        return rand
    }

    private func color(for node:Node<T>, count:Int, rand:Random) -> Int {
        let remainingColors = Set(self.adjacencyList[node]!.map() { $0.color })
        let n = count - self.degree(of: node)
        let index = rand(n)
        var i = 0
        while remainingColors.contains(i) {
            i += 1
        }
        for _ in 0..<index {
            i += 1
            while remainingColors.contains(i) {
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

    private func _colorGraph(count:Int, rand:Random ) -> ColorAssignment<T> {
        guard self.nodes.count > 1 else {
            guard let node = self.nodes.first else {
                return [:]
            }
            let color = rand(count)
            return [node.value:color]
        }
        let minimumNode = self.nodes.min() { self.degree(of: $0) < self.degree(of: $1) }!
        let subGraph = try! self.graph(without: minimumNode.value)
        var colorAssignment = subGraph._colorGraph(count: count, rand: rand)
        let color = self.color(for: minimumNode, count: count, rand: rand)
        colorAssignment[minimumNode.value] = color
        return colorAssignment
    }

    internal func colorGraph<R: RandomNumberGenerator>(count:Int, using random:R? = nil) -> ColorAssignment<T> {
        let rand = self.randomGenerator(using: random)
        return self._colorGraph(count: count, rand: rand)
    }

}
