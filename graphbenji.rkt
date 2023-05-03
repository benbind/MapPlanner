#lang dssl2

# HW4: Graph
let eight_principles = ["Know your rights.",
     "Acknowledge your sources.",
     "Protect your work.",
     "Avoid suspicion.",
     "Do your own work.",
     "Never falsify a record or permit another person to do so.",
     "Never fabricate data, citations, or experimental results.",
     "Always tell the truth when discussing your work with your instructor."]
import cons
import 'hw4-lib/dictionaries.rkt'
import sbox_hash

###
### REPRESENTATION
###

# A Vertex is a natural number.
let Vertex? = nat?

# A VertexList is either
#  - None, or
#  - cons(v, vs), where v is a Vertex and vs is a VertexList
let VertexList? = Cons.ListC[Vertex?]

# A Weight is a real number. (It’s a number, but it’s neither infinite
# nor not-a-number.)
let Weight? = AndC(num?, NotC(OrC(inf, -inf, nan)))

# An OptWeight is either
# - a Weight, or
# - None
let OptWeight? = OrC(Weight?, NoneC)

# A WEdge is WEdge(Vertex, Vertex, Weight)
struct WEdge:
    let u: Vertex?
    let v: Vertex?
    let w: Weight?

# A WEdgeList is either
#  - None, or
#  - cons(w, ws), where w is a WEdge and ws is a WEdgeList
let WEdgeList? = Cons.ListC[WEdge?]

# A weighted, undirected graph ADT.
interface WUGRAPH:

    # Returns the number of vertices in the graph. (The vertices
    # are numbered 0, 1, ..., k - 1.)
    def len(self) -> nat?

    # Sets the weight of the edge between u and v to be w. Passing a
    # real number for w updates or adds the edge to have that weight,
    # whereas providing providing None for w removes the edge if
    # present. (In other words, this operation is idempotent.)
    def set_edge(self, u: Vertex?, v: Vertex?, w: OptWeight?) -> NoneC

    # Gets the weight of the edge between u and v, or None if there
    # is no such edge.
    def get_edge(self, u: Vertex?, v: Vertex?) -> OptWeight?

    # Gets a list of all vertices adjacent to v. (The order of the
    # list is unspecified.)
    def get_adjacent(self, v: Vertex?) -> VertexList?

    # Gets a list of all edges in the graph, in an unspecified order.
    # This list only includes one direction for each edge. For
    # example, if there is an edge of weight 10 between vertices
    # 1 and 3, then exactly one of WEdge(1, 3, 10) or WEdge(3, 1, 10)
    # will be in the result list, but not both.
    def get_all_edges(self) -> WEdgeList?

class WuGraph (WUGRAPH):
    #   ^ ADD YOUR FIELDS HERE
    let _matrix
    let _size

    def __init__(self, size: nat?):
        self._size = size
        self._matrix = [None; self._size]
        for x in range(self._size):
            self._matrix[x] = [None; self._size]
    def len(self):
        return self._size
    def set_edge(self, u: Vertex?, v: Vertex?, w: OptWeight?):
        self._matrix[u][v]= w
        self._matrix[v][u] = w
    def get_edge(self, u: Vertex?, v: Vertex?):
        return self._matrix[u][v]
    def get_adjacent(self, v: Vertex?):
        let list = None
        for x in range(self._size):
            let edge = self._matrix[v][x]
            if edge != None:
                list = cons(x, list)
        return list
    def get_all_edges(self):
        let list = None
        for x in range(self._size):
            for y in range(x, self._size):
                let edge = self._matrix[x][y]
                if edge != None:
                    list = cons(WEdge(x,y, self._matrix[x][y]), list)
        return list
    
        
    #   ^ ADD YOUR CODE HERE

# Other methods you may need can go here.


###
### List helpers
###

# To test methods that return lists with elements in an unspecified
# order, you can use these functions for sorting. Sorting these lists
# will put their elements in a predictable order, order which you can
# use when writing down the expected result part of your tests.

# sort_vertices : ListOf[Vertex] -> ListOf[Vertex]
# Sorts a list of numbers.
def sort_vertices(lst: Cons.list?) -> Cons.list?:
    def vertex_lt?(u, v): return u < v
    return Cons.sort[Vertex?](vertex_lt?, lst)

# sort_edges : ListOf[WEdge] -> ListOf[WEdge]
# Sorts a list of weighted edges, lexicographically
# ASSUMPTION: There's no need to compare weights because
# the same edge can’t appear with different weights.
def sort_edges(lst: Cons.list?) -> Cons.list?:
    def edge_lt?(e1, e2):
        return e1.u < e2.u or (e1.u == e2.u and e1.v < e2.v)
    return Cons.sort[WEdge?](edge_lt?, lst)

###
### BUILDING GRAPHS
###

def example_graph() -> WuGraph?:
    let result = WuGraph(6) # 6-vertex graph from the assignment
    result.set_edge(0,1,12)
    result.set_edge(1,2,31)
    result.set_edge(1,3,56)
    result.set_edge(2,4,-2)
    result.set_edge(2,5,7)
    result.set_edge(3,4,9)
    result.set_edge(3,5,1)
    return result
#   ^ ADD YOUR CODE HERE

struct CityMap:
    let graph
    let city_name_to_node_id
    let node_id_to_city_name

def my_neck_of_the_woods():
    let hometown = WuGraph(6)
    hometown.set_edge(0,1,12)
    hometown.set_edge(0,5,3)
    hometown.set_edge(0,2,15)
    hometown.set_edge(2,5,4)
    hometown.set_edge(2,3,10)
    
    let city_node = HashTable(5, make_sbox_hash())
    city_node.put('Madison', 0)
    city_node.put('Middleton', 1)
    city_node.put('Milwaukee', 2)
    city_node.put('Verona', 3)
    city_node.put('Fond du Lac', 4)
    let node_city = ['Madison', 'Middleton', 'Milwaukee', 'Verona', 'Fond du Lac']
    return CityMap(hometown, city_node, node_city)
#   ^ ADD YOUR CODE HERE

###
### DFS
###
def dfs_helper(graph, v, f, seen):
    if seen[v] == False:
        seen[v]= True
        let node = v
        v = f(v)
        for adjacent in Cons.to_vec(graph.get_adjacent(node)):
            dfs_helper(graph, adjacent, f, seen)
# dfs : WUGRAPH Vertex [Vertex -> any] -> None
# Performs a depth-first search starting at `start`, applying `f`
# to each vertex once as it is discovered by the search.
def dfs(graph: WUGRAPH!, start: Vertex?, f: FunC[Vertex?, AnyC]) -> NoneC:
    let seen = [False; graph.len()]
    dfs_helper(graph, start, f, seen)
    
    
#   ^ ADD YOUR CODE HERE

# dfs_to_list : WUGRAPH Vertex -> ListOf[Vertex]
# Performs a depth-first search starting at `start` and returns a
# list of all reachable vertices.
#
# This function uses your `dfs` function to build a list in the
# order of the search. It will pass the test below if your dfs visits
# each reachable vertex once, regardless of the order in which it calls
# `f` on them. However, you should test it more thoroughly than that
# to make sure it is calling `f` (and thus exploring the graph) in
# a correct order.
def dfs_to_list(graph: WUGRAPH!, start: Vertex?) -> VertexList?:
    let list = None
    # Add to the front when we visit a node
    dfs(graph, start, lambda new: list = cons(new, list))
    # Reverse to the get elements in visiting order.
    Cons.rev(list)

###
### TESTING
###

## You should test your code thoroughly. Here is one test to get you started:

test 'dfs_to_list(example_graph())':
    # Cons.from_vec is a convenience function from the `cons` library that
    # allows you to write a vector (using the nice vector syntax), and get
    # a linked list with the same elements.
    assert sort_vertices(dfs_to_list(example_graph(), 0)) \
        == Cons.from_vec([0, 1, 2, 3, 4, 5])
        
test 'test':
    let home = my_neck_of_the_woods().graph
    let citynode = my_neck_of_the_woods().city_name_to_node_id
    let nodecity = my_neck_of_the_woods().node_id_to_city_name
    assert home.get_edge(0,5) == 3
    assert home.get_edge(5,0) == 3
    assert home.get_edge(0,3) == None
    assert home.len() == 6
    assert sort_edges(home.get_all_edges()) == Cons.from_vec([WEdge(0, 1, 12), WEdge(0, 2, 15),
     WEdge(0, 5, 3), WEdge(2, 3, 10), WEdge(2, 5, 4)])
    assert_error home.get_edge(0,6)
    let madison = citynode.get('Madison')
    let middleton = citynode.get('Middleton')
    assert home.get_edge(madison, middleton) == 12    
    let verona = citynode.get('Verona')
    assert home.get_edge(madison, verona) == None
    let adj_to_1 = home.get_adjacent(1)
    assert sort_vertices(adj_to_1) == Cons.from_vec([0])
    let adj_to_0 = home.get_adjacent(0)
    assert sort_vertices(adj_to_0) == Cons.from_vec([1,2,5])
    