#lang dssl2

# HW2: Stacks and Queues

import ring_buffer

interface STACK[T]:
    def push(self, element: T) -> NoneC
    def pop(self) -> T
    def empty?(self) -> bool?

# Defined in the `ring_buffer` library; copied here for reference.
# Do not uncomment! or you'll get errors.
# interface QUEUE[T]:
#     def enqueue(self, element: T) -> NoneC
#     def dequeue(self) -> T
#     def empty?(self) -> bool?

# Linked-list node struct (implementation detail):
struct _cons:
    let data
    let next: OrC(_cons?, NoneC)

###
### ListStack
###

class ListStack[T] (STACK):

    # Any fields you may need can go here.

    # Constructs an empty ListStack.
    def __init__ (self):
        self.contains = []
        
    #   ^ ADD YOUR CODE HERE
    def push(self, x):
        self.contains.append(x)
    
    def pop(self):
        return self.contains.pop()

    # Other methods you may need can go here.

test "woefully insufficient":
    let s = ListStack()
    s.push(2)
    assert s.pop() == 2

###
### ListQueue
###

class ListQueue[T] (QUEUE):

    # Any fields you may need can go here.

    # Constructs an empty ListQueue.
    def __init__ (self):
        pass
    #   ^ ADD YOUR CODE HERE

    # Other methods you may need can go here.

test "woefully insufficient, part 2":
    let q = ListQueue()
    q.enqueue(2)
    assert q.dequeue() == 2

###
### Playlists
###

struct song:
    let title: str?
    let artist: str?
    let album: str?

# Enqueue five songs of your choice to the given queue, then return the first
# song that should play.
def fill_playlist (q: QUEUE!):
    pass
#   ^ ADD YOUR CODE HERE

test "ListQueue playlist":
    pass

# To construct a RingBuffer: RingBuffer(capacity)
test "RingBuffer playlist":
    pass
