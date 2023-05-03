#lang dssl2

# Final project: Trip Planner
let eight_principles = ["Know your rights.",
"Acknowledge your sources.",
"Protect your work.",
"Avoid suspicion.",
"Do your own work.",
"Never falsify a record or permit another person to do so.",
"Never fabricate data, citations, or experimental results.",
"Always tell the truth when discussing your work with your instructor."]
import cons
import "project-lib/dictionaries.rkt"
import "project-lib/graph.rkt"
import 'project-lib/stack-queue.rkt'
import 'project-lib/binheap.rkt'
import sbox_hash
### Basic Types ###

#  - Latitudes and longitudes are numbers:
let Lat?  = num?
let Lon?  = num?

#  - Point-of-interest categories and names are strings:
let Cat?  = str?
let Name? = str?

### Raw Item Types ###

#  - Raw positions are 2-element vectors with a latitude and a longitude
let RawPos? = TupC[Lat?, Lon?]

#  - Raw road segments are 4-element vectors with the latitude and
#    longitude of their first endpoint, then the latitude and longitude
#    of their second endpoint
let RawSeg? = TupC[Lat?, Lon?, Lat?, Lon?]

#  - Raw points-of-interest are 4-element vectors with a latitude, a
#    longitude, a point-of-interest category, and a name
let RawPOI? = TupC[Lat?, Lon?, Cat?, Name?]

### Contract Helpers ###

# ListC[T] is a list of `T`s (linear time):
let ListC = Cons.ListC
# List of unspecified element type (constant time):
let List? = Cons.list?


interface TRIP_PLANNER:

    # Returns the positions of all the points-of-interest that belong to
    # the given category.
    def locate_all(
            self,
            dst_cat:  Cat?           # point-of-interest category
        )   ->        ListC[RawPos?] # positions of the POIs

    # Returns the shortest route, if any, from the given source position
    # to the point-of-interest with the given name.
    def plan_route(
            self,
            src_lat:  Lat?,          # starting latitude
            src_lon:  Lon?,          # starting longitude
            dst_name: Name?          # name of goal
        )   ->        ListC[RawPos?] # path to goal

    # Finds no more than `n` points-of-interest of the given category
    # nearest to the source position.
    def find_nearby(
            self,
            src_lat:  Lat?,          # starting latitude
            src_lon:  Lon?,          # starting longitude
            dst_cat:  Cat?,          # point-of-interest category
            n:        nat?           # maximum number of results
        )   ->        ListC[RawPOI?] # list of nearby POIs
#struct cons:
    #let data
    #let next: OrC(cons?, NoneC)
struct node:
    let num
    let priority
class TripPlanner (TRIP_PLANNER):
    let _segments
    let _pois
    let _poi_to_num
    let _num_to_poi
    let _seg_to_num
    let _num_to_seg
    let _poi_to_name
    let _name_to_poi
    let _graph
    let _allpos
    let _allposvec
    def __init__(self, segments, pois):
        self._segments = segments
        self._pois = pois
        self._allpos = cons(None, None)
        for seg in self._segments:
            let seg1 = [seg[0], seg[1]]
            let seg2 = [seg[2], seg[3]]
            if not self.existingpos(seg1):
                self._allpos = cons(seg1, self._allpos)
            if not self.existingpos(seg2):
                self._allpos = cons(seg2, self._allpos)
        self._allposvec = Cons.to_vec(self._allpos)
        self._seg_to_num = HashTable(len(self._allposvec), make_sbox_hash())
        self._num_to_seg = HashTable(len(self._allposvec), make_sbox_hash())
        for x in range(len(self._allposvec)):
            self._seg_to_num.put(self._allposvec[x],x)
            self._num_to_seg.put(x, self._allposvec[x])
        self._graph = WuGraph(len(self._allposvec))
        self.create_graph()
        self._name_to_poi = HashTable(len(pois), make_sbox_hash())
        self._poi_to_name = HashTable(len(pois), make_sbox_hash())
        self._poi_to_num = HashTable(len(pois), make_sbox_hash())
        self._num_to_poi = HashTable(len(pois), make_sbox_hash())
        for x in range (len(self._allposvec)):
            let num = self._seg_to_num.get(self._allposvec[x])
            self._num_to_poi.put(num, cons(None,None))
        for poi in self._pois:
            let name = poi[3]
            self._name_to_poi.put(name, poi)
            self._poi_to_name.put(poi, name)
            let num = self._seg_to_num.get([poi[0], poi[1]])
            let allpois = self._num_to_poi.get(num)
            allpois = cons(poi, allpois)
            self._num_to_poi.del(num)
            self._num_to_poi.put(num, allpois)
            self._poi_to_num.put(poi, num)
    def existingpos(self, pos):
        let current = self._allpos
        while current.next != None:
            if current == pos:
                return True
            current = current.next
        if current != None:
            if current == pos:
                return True
           
    def find_dist(self,seg):
        let x = (seg[2]-seg[0])*(seg[2]-seg[0])
        let y = (seg[3]-seg[1])*(seg[3]-seg[1])
        let z = x+y
        return z.sqrt() #gets euclidian distance of a segment (from one poi to another)
    
    
    def create_graph(self):                    
        for seg in self._segments:
            self._graph.set_edge(self._seg_to_num.get(([seg[0],seg[1]])), self._seg_to_num.get([seg[2],seg[3]]), self.find_dist(seg))
                          
           
    def locate_all(self, category):
        let located = None
        let completed  = [False; len(Cons.to_vec(self._allpos))]
        for poi in self._pois:
            if poi[2] == category and completed[self._seg_to_num.get([poi[0],poi[1]])] == False:
                located = cons([poi[0],poi[1]], located) #returns a linked list of all pois in a category
                completed[self._seg_to_num.get([poi[0],poi[1]])] = True
        return located
    def dijkstra(self, start):
        let distances = [inf; self._graph.len()]
        distances[start] = 0
        let pred = [None; self._graph.len()]
        pred[start] = start
        let todo = BinHeap[nat?](self._graph.len(), λ x, y: distances[x] < distances[y])
        let done = [False; self._graph.len()]
        todo.insert(start)
        while todo.len() != 0:
            let v = todo.find_min()
            todo.remove_min()
            if done[v] == False:
                done[v] = True
                let adj_list = self._graph.get_adjacent(v)
                while adj_list != None:
                    let weight = self._graph.get_edge(v, adj_list.data)
                    if distances[v]+weight < distances[adj_list.data]:
                        distances[adj_list.data] = distances[v]+ weight
                        pred[adj_list.data] = v
                        todo.insert(adj_list.data)
                    adj_list = adj_list.next
                        
        return [distances, pred]    
            
    def plan_route(self, lat, long, name):
        if not self._name_to_poi.mem?(name):
            return None
        let pos = [lat, long]
        let num = self._seg_to_num.get(pos)
        let table = self.dijkstra(num)
        let destpoi = self._name_to_poi.get(name)
        let destination = self._poi_to_num.get(destpoi)
        let route = None
        if table[1][destination] == None and destination != num:
            return None
        while table[1][destination] != destination:
            route = cons(self._num_to_seg.get(destination), route)
            destination = table[1][destination]
        route = cons(self._num_to_seg.get(destination), route)
        return route        
    def dijkstra_remodeled(self, pos, cat, limit):
        let distances = [inf; len(self._allposvec)]
        distances[self._seg_to_num.get(pos)] = 0
        let start = self._seg_to_num.get(pos)
        let pred = [None; len(self._allposvec)]
        let done = [False; len(self._allposvec)]
        let todo = BinHeap[node?](10, λ x, y: x.priority < y.priority)
        let inrange = cons(None, None)
        todo.insert(node(start, 0))
        let counter = 0
        while counter < limit and todo.len() != 0:
            let v = todo.find_min()
            let v_num = v.num
            todo.remove_min()
            if done[v_num] ==False:
                done[v_num] = True
                if self._num_to_poi.mem?(v_num):
                    if self._num_to_poi.get(v_num) != None:
                        if self._num_to_poi.get(v_num).data != None:
                            let allpois =self._num_to_poi.get(v_num)
                            let picked
                            let match = False
                            while allpois != None and allpois.data != None:
                                if cat == allpois.data[2]:
                                    match = True
                                    picked = allpois.data
                                allpois = allpois.next
                            if match == True:
                                counter = counter +1
                                if counter == 1:
                                    inrange = cons(picked, None)
                                else:
                                    inrange = cons(picked, inrange)
                let adj = self._graph.get_adjacent(v_num)
                if adj == None:
                    return inrange
                while adj.data != None:
                    let weight = distances[v_num] + self._graph.get_edge(v_num, adj.data)
                    if weight < distances[adj.data]:
                        todo.insert(node(adj.data, weight))
                        distances[adj.data] = weight
                        pred[adj.data] = v_num
                    adj = adj.next
                    if adj == None:
                        break
                if counter == 0:
                    inrange = None
        return inrange      
                                    
                            
                            
                        
        
    def find_nearby(self, lat, long, cat, limit):
        let pos = [lat, long]
        return self.dijkstra_remodeled(pos, cat, limit)
        pass
#   ^ ADD YOUR CODE HERE
def my_first_example():
    return TripPlanner([[0,0, 0,1], [0,0, 1,0]],
                       [[0,0, "bar", "The Empty Bottle"],
                        [0,1, "food", "Pelmeni"]])
                        
def big_graph():
    return TripPlanner([[0,0,2,-2],[0,0,-3,-2], [-3,-2,-1,1], [ 0,0,-1,1], [0,0,1,0],[1,0,2,1],[2,1,4,1]], \
    [[0,0, 'food', 'McDonalds'], [-3,-2, 'school', 'NU'],\
    [2,-2, 'house', 'Alex'], [-1,1, 'house', 'Ben'], [2,1,'store', 'Target'], [4,1, 'food', 'BKing']])
def two_graphs():
    return TripPlanner([[0,0,0,-1],[0,0,1,0],[4,5,4,6]], [[0,0, 'shoes', 'Jordans'],\
    [0, -1, 'food', 'Annies'],[1,0, 'school', 'NU'], [4,5,'school', 'Cornell'],\
    [4,6, 'school', 'Duke']])              
#lang dssl2
test 'big graph':
    let locate = big_graph().locate_all('food')
    assert locate == cons([4,1], cons([0,0], None))
    let plan1 = big_graph().plan_route(0,0, 'Target')
    assert Cons.to_vec(plan1) == [[0,0], [1,0], [2,1]]
    let plan2 = big_graph().plan_route(-1,1,'McDonalds')
    assert Cons.to_vec(plan2) == [[-1,1], [0,0]]
    let plan3 = big_graph().plan_route(0,0, 'Jack')
    assert Cons.to_vec(plan3) == []
    let find1 = big_graph().find_nearby(-1,1, 'food', 1)
    assert Cons.to_vec(find1) == [[0,0, 'food', 'McDonalds']]
    let find2 = big_graph().find_nearby(-1,1, 'food', 2)
    assert Cons.to_vec(find2) == [[ 4,1, 'food', 'BKing'],[0,0, 'food', 'McDonalds']]
    let find3 = big_graph().find_nearby(0,0, 'Blake', 2)
    assert Cons.to_vec(find3) == []
test 'two_graphs':
    let result = two_graphs().plan_route(0,0, 'Cornell')
    assert Cons.to_vec(result) == []
