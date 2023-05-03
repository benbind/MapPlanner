#lang dssl2

# HW3: Dictionaries
let eight_principles = ["Know your rights.",
"Acknowledge your sources.",
"Protect your work.",
"Avoid suspicion.",
"Do your own work.",
"Never falsify a record or permit another person to do so.",
"Never fabricate data, citations, or experimental results.",
"Always tell the truth when discussing your work with your instructor."]

import sbox_hash

# A signature for the dictionary ADT. The contract parameters `K` and
# `V` are the key and value types of the dictionary, respectively.
interface DICT[K, V]:
    # Returns the number of key-value pairs in the dictionary.
    def len(self) -> nat?
    # Is the given key mapped by the dictionary?
    def mem?(self, key: K) -> bool?
    # Gets the value associated with the given key; calls `error` if the
    # key is not present.
    def get(self, key: K) -> V
    # Modifies the dictionary to associate the given key and value. If the
    # key already exists, its value is replaced.
    def put(self, key: K, value: V) -> NoneC
    # Modifes the dictionary by deleting the association of the given key.
    def del(self, key: K) -> NoneC
    # The following method allows dictionaries to be printed
    def __print__(self, print)

struct _cons:
    let key
    let value
    let next: OrC(_cons?, NoneC)
class AssociationList[K, V] (DICT):

    let head
    let length

    #   ^ ADDITIONAL FIELDS HERE

    def __init__(self):
        self.head = None
        self.length = 0
        
    def len(self):
        return self.length
    def mem?(self, key):
        let current = self.head
        while current != None:
            if current.key == key:
                return True
            current = current.next
        return False
               
    
    def get(self, key):
        let current = self.head
        while current.key != key and current != None:
            current = current.next
        if current == None:
            return error('this key is not in the dictionary')
        return current.value
        
    def put(self, key:K, value:V):
        if self.mem?(key):
            let current = self.head
            while current != None:
                if current.key == key:
                    current.value = value
                    self.length = self.length + 1
                current = current.next
        else:
            self.head = _cons(key, value, self.head)
            self.length = self.length + 1
            
             
        pass
        
    def del(self, key: K):
        if self.head.key == key:
            self.head = self.head.next
            self.length = self.length - 1
        elif not self.mem?(key):
            return
        else:
            let current = self.head
            while current != None:
                if current.next.key == key:
                    current.next = current.next.next
                    self.length = self.length-1
        pass
    
    #   ^ ADD YOUR CODE HERE

    # See above.
    def __print__(self, print):
        print("#<object:AssociationList head=%p>", self.head)

    # Other methods you may need can go here.


test 'yOu nEeD MorE tEsTs':
    let a = AssociationList()
    assert not a.mem?('hello')
    a.put('hello', 5)
    assert a.len() == 1
    assert a.mem?('hello')
    assert a.get('hello') == 5
test 'AssociationLists':
    let b = AssociationList()
    b.put('z', 4)
    assert b.mem?('z')
    assert b.len() == 1
    assert b.get('z') == 4
    b.del('z')
    assert not b.mem?('z')
    assert b.len() == 0
    b.put('x', 5)
    b.put('x', 4)
    assert b.get('x') == 4
    assert_error b.get('y')

   
    


class HashTable[K, V] (DICT):
    let _hash
    let _size
    let _data
    let nbuckets    

    def __init__(self, nbuckets: nat?, hash: FunC[AnyC, nat?]):
        self._hash = hash
        self._size = 0
        self.nbuckets = nbuckets
        self._data = [None; nbuckets]
        for x in range(len(self._data)):
            self._data[x] = AssociationList()
        pass
    def len(self):
        return self._size
        pass
    def find_bucket(self,key):
        return self._hash(key) % self.nbuckets
    def mem?(self, key):
        let bucket = self.find_bucket(key)
        return self._data[bucket].mem?(key)
        pass
    def get(self, key):
        let bucket = self.find_bucket(key)
        return self._data[bucket].get(key)
        pass
    def put(self, key, value):
        let bucket = self.find_bucket(key)
        if not self._data[bucket].mem?(key):
            self._size = self._size + 1
        self._data[bucket].put(key, value)
        pass
    def del(self, key):
        let bucket = self.find_bucket(key)
        if not self.mem?(key):
            return
        self._size = self._size -1
        self._data[bucket].del(key)
        pass
        
    #   ^ ADD YOUR CODE HERE

    # This avoids trying to print the hash function, since it's not really
    # printable and isn’t useful to see anyway:
    def __print__(self, print):
        print("#<object:HashTable  _hash=... _size=%p _data=%p>",
              self._size, self._data)

    # Other methods you may need can go here.


# first_char_hasher(String) -> Natural
# A simple and bad hash function that just returns the ASCII code
# of the first character.
# Useful for debugging because it's easily predictable.
def first_char_hasher(s: str?) -> int?:
    if s.len() == 0:
        return 0
    else:
        return int(s[0])

test 'yOu nEeD MorE tEsTs, part 2':
    let h = HashTable(10, make_sbox_hash())
    assert not h.mem?('hello')
    h.put('hello', 5)
    assert h.len() == 1
    assert h.mem?('hello')
    assert h.get('hello') == 5
test 'HashTable':
    let h = HashTable(15, make_sbox_hash())
    assert_error h.get('15')
    assert h.len() == 0
    assert h.del('15') == None
    h.put('jacket', 5)
    assert h.len() == 1
    assert h.get('jacket') == 5
    h.del('jacket') 
    assert h.len() == 0
    assert h.del('jacket') == None
struct food:
    let name
    let type
def compose_menu(d: DICT!) -> DICT?:
    d.put('Benji', food('Pesto Pasta', 'Itlalian'))
    d.put('Alex', food('Pepperoni Pizza', 'Italian'))
    d.put('Jeremy', food('Hamburger', 'American'))
    d.put('Luke', food('Burrito', 'Mexican'))
    d.put('Scarlett', food('Chicken Tiki Masala', 'Indian'))
    return d
    pass
#   ^ ADD YOUR CODE HERE

test "AssociationList menu":
    let menu = AssociationList()
    menu = compose_menu(menu)
    assert menu.get('Scarlett').type == 'Indian'
    pass

test "HashTable menu":
    let menuhash = HashTable(7, make_sbox_hash())
    let menu = compose_menu(menuhash)
    assert menu.get('Scarlett').type == 'Indian'
    pass
