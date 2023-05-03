#lang dssl2

# HW5: Binary Heaps
let eight_principles = ["Know your rights.",
"Acknowledge your sources.",
"Protect your work.",
"Avoid suspicion.",
"Do your own work.",
"Never falsify a record or permit another person to do so.",
"Never fabricate data, citations, or experimental results.",
"Always tell the truth when discussing your work with your instructor."]
interface PRIORITY_QUEUE[X]:
    # Returns the number of elements in the priority queue.
    def len(self) -> nat?
    # Returns the smallest element; error if empty.
    def find_min(self) -> X
    # Removes the smallest element; error if empty.
    def remove_min(self) -> NoneC
    # Inserts an element; error if full.
    def insert(self, element: X) -> NoneC

# Class implementing the PRIORITY_QUEUE ADT as a binary heap.
class BinHeap[X] (PRIORITY_QUEUE):
    let _data: VecC[OrC(X, NoneC)]
    let _size: nat?
    let _lt?:  FunC[X, X, bool?]

    # Constructs a new binary heap with the given capacity and
    # less-than function for type X.
    def __init__(self, capacity, lt?):
        self._data = [None; capacity]
        self._size = 0
        self._lt? = lt?
        pass
    def len(self):
        return self._size
    def find_min(self):
        if self == []:
            error('The binheap is empty')
        return self._data[0]
    def sort_helper(self, node):
        let lkid = node*2+1
        let rkid = node*2+2
        if node >= self._size:
            return
        else:
            if lkid >= self._size:
                return
        if rkid < self._size:
            if self._lt?(self._data[rkid], self._data[lkid]):
                    if self._lt?(self._data[rkid], self._data[node]):
                        let save = self._data[rkid]
                        self._data[rkid] = self._data[node]
                        self._data[node] = save
                        self.sort_helper(rkid)
                    return
            if self._lt?(self._data[lkid], self._data[node]):
                let save = self._data[lkid]
                self._data[lkid] = self._data[node]
                self._data[node] = save
                self.sort_helper(lkid)
        else:
            if lkid < self._size:
                if self._lt?(self._data[lkid], self._data[node]):
                    let save = self._data[lkid]
                    self._data[lkid] = self._data[node]
                    self._data[node] = save
                    self.sort_helper(lkid)       
        return
    def remove_min(self):
        if self.len() == 0:
            error("The graph is empty")
        let first = self._data[0]
        let last = self._data[self._size-1]
        self._data[0] = last
        self._data[self._size-1] = None
        self._size = self._size-1
        self.sort_helper(0)
        println(self._data)
    def bubbleup(self, node):
        let parent = int((node-1)/2)
        if (node-1)/2 < 0:
            return
        if self._lt?(self._data[node], self._data[parent]):
            let saved = self._data[parent]
            self._data[parent] = self._data[node]
            self._data[node] = saved
            self.bubbleup(parent)
        return
    def insert(self, element):
        if len(self._data) < self._size +1:
            error('You cannot insert any more')
        self._data[self._size] = element
        self._size = self._size + 1
        self.bubbleup(self._size-1)
        
        
            
        
    #   ^ ADD YOUR CODE HERE

# Other methods you may need can go here.


# Woefully insufficient test.
test 'insert, insert, remove_min':
    # The `nat?` here means our elements are restricted to `nat?`s.
    let h = BinHeap[nat?](10, λ x, y: x < y)
    h.insert(1)
    assert h.find_min() == 1
    h.insert(4)
    h.insert(8)
    h.insert(5)
    h.insert(2)
    assert h.len() ==5
    assert h.find_min() == 1
    h.remove_min()
    assert h.len() ==4
    
    let small = BinHeap[nat?](1, λ x, y: x < y)
    small.insert(2)
    assert_error small.insert(3)
    small.remove_min()
    let MT = BinHeap[nat?](0, λ x, y: x < y)
    assert_error MT.remove_min()

# Sorts a vector of Xs, given a less-than function for Xs.
#
# This function performs a heap sort by inserting all of the
# elements of v into a fresh heap, then removing them in
# order and placing them back in v.
def heap_sort[X](v: VecC[X], lt?: FunC[X, X, bool?]) -> NoneC:
    let bin = BinHeap[X](v.len(), lt?)
    for x in range(v.len()):
        bin.insert(v[x])
    for x in range(v.len()):
        v[x] = bin.find_min()
        bin.remove_min()
        
#   ^ ADD YOUR CODE HERE

test 'heap sort descending':
    let v = [3, 7, 0, 2, 1]
    heap_sort(v, λ x, y: x > y)
    assert v == [7, 3, 2, 1, 0]
    heap_sort(v, λ x, y: x < y)
    assert v == [0, 1, 2, 3, 7]

# Sorting by birthday.

struct person:
    let name: str?
    let birth_month: nat?
    let birth_day: nat?
def birthday_helper(person1, person2):
    if person1.birth_month == person2.birth_month:
        return person1.birth_day < person2.birth_day
    else:
        return person1.birth_month < person2.birth_month
    return True
def earliest_birthday() -> str?:
    let ben = person('Ben', 1, 18)
    let maggie = person('Maggie', 8, 20)
    let dad = person('Dad', 8, 29)
    let dom = person('Dom', 12, 26)
    let chad = person('Chad', 2, 15)
    let people = [ben, maggie, dad, dom, chad]
    heap_sort(people, birthday_helper)
    return people[0].name
test 'Earliest_Birthday':
    assert earliest_birthday() == 'Ben'
#   ^ ADD YOUR CODE HERE
