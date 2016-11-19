module szelessegi

import GenEq
import StdEnv

:: Weight = Infinite | Weight Int 
:: Color = White | Gray | Black
:: Vertex :== Int
:: Adjacency :== (Color, [Weight]) 
:: EdgeList :== (Color, [(Vertex, Weight)])
listAdj =
  [(White,[(Weight 0),(Weight 1),Infinite,Infinite,Infinite,Infinite,Infinite])
  ,(Gray,[(Weight 1),(Weight 0),Infinite,(Weight 1),Infinite,Infinite,(Weight 1)])
  ,(Black,[(Weight 1),Infinite,(Weight 0),Infinite,Infinite,Infinite,Infinite])
  ,(Gray,[Infinite,(Weight 1),Infinite,(Weight 0),(Weight 1),Infinite,Infinite])
  ,(White,[Infinite,Infinite,Infinite,(Weight 1),(Weight 0),Infinite,Infinite])
  ,(Black,[Infinite,Infinite,(Weight 1),Infinite,(Weight 1),(Weight 0),Infinite])
  ,(White,[Infinite,Infinite,Infinite,Infinite,Infinite,(Weight 1),(Weight 0)])
  ]

listEdge :: [] EdgeList
listEdge =
  [(White,[(1,(Weight 1))])
  ,(Gray,[(0,(Weight 1)),(3,(Weight 1)),(6,(Weight 1))])
  ,(Black,[(0,(Weight 1))])
  ,(Gray,[(1,(Weight 1)),(4,(Weight 1))])
  ,(White,[(3,(Weight 1))])
  ,(Black,[(2,(Weight 1)),(4,(Weight 1))])
  ,(White,[(5,(Weight 1))])
  ] 
derive gEq Color,Weight

/****************NODE********************/  
class Node t where
  newNode      :: Int -> t
  getColor     :: t -> Color
  color        :: t Color -> t
  neighbours   :: t -> [Vertex]
  add          :: t -> t
  addNeighbour :: t Vertex Weight -> t

/****************ADJACENCY********************/  
instance Node Adjacency where
  newNode a = (White,repeatn a Infinite ++ [Weight 0])
  getColor node = fst node
  color node color =  (color,snd node)  
  neighbours node = [nr \\ nr<-[0..(length (snd node))] & weight <-(snd node) | not (weight === Infinite || weight === Weight 0)]
  add node = (fst node,(snd node)++[Infinite])
  addNeighbour node vertex weight = (fst node,take vertex (snd node) ++ [weight] ++ drop (vertex+1) (snd node))
  //addNeighbour node vertex weight = (fst node, updateAt vertex weight (snd node))

/****************EDGELSIT********************/  
instance Node EdgeList where
  newNode a = (White,[])
  getColor node = fst node
  color node color =  (color,snd node) 
  neighbours node = map fst (snd node) 
  add node = node
  addNeighbour node vertex weight = (fst node, insert f (vertex,weight) (snd node))
    where 
      f (v1,w1) (v2,w2) = v1<v2 
      


/********************CONVECSIONS********************/
adj :: Int -> Adjacency
adj x = newNode x

edge :: Int -> EdgeList
edge x = newNode x 

arrayAdj :: {} Adjacency
arrayAdj = { x \\ x <- listAdj }

arrayEdge :: {} EdgeList
arrayEdge = { x \\ x <- listEdge }
toArray list ={e \\ e <- list}
toList array =[e \\ e <-: array]

class Graph t1 t2 | Node t2 where
    resetGraph  :: (t1 t2) -> (t1 t2)
    graphSize   :: (t1 t2) -> Int
    getNode     :: (t1 t2) Vertex -> t2
    addNode     :: (t1 t2) -> (t1 t2)
    updateGraph :: (t1 t2) Vertex t2 -> (t1 t2)

instance Graph [] t2 | Node t2 where
	resetGraph graph = map (\(params) = (color params White) ) graph	
	graphSize graph = length graph
	getNode graph n =  graph !! n
	addNode graph = graph ++ [newNode (length graph)]
	updateGraph graph vertex node = updateAt vertex node graph
instance Graph {} t2 | Node t2 where
	resetGraph graph =  { color node White \\ node <-: graph }
	graphSize graph = size graph
	getNode graph n =  select graph n
	addNode graph = toArray(toList graph ++ [newNode (size graph)])
	updateGraph graph vertex node = toArray (updateAt vertex node (toList graph))
	
whiteNeighbours :: (t1 t2) Vertex -> [Vertex] | Graph t1 t2
whiteNeighbours graph vertex = flatten(  map (\(ver) = f ver (getColor (getNode graph ver) === White) ) (neighbours (getNode graph vertex)))
  where
    f vertex bool 
      | bool == True = [vertex]
                     = [] 
addEdgeToGraph :: (t1 t2) Vertex Vertex Weight -> (t1 t2) | Graph t1 t2
addEdgeToGraph graph v1 v2 w = updateGraph graph v1 (addNeighbour (getNode graph v1) v2 w )

/********************START********************/
Start = test_addEdgeToGraph

/********************TESTS********************/
test_addEdgeToGraph =
  [ neighbours (getNode (addEdgeToGraph listAdj 3 0 (Weight 5)) 3) == [0,1,4]
  , neighbours (getNode (addEdgeToGraph listEdge 3 0 (Weight 5)) 3) == [0,1,4]
  , neighbours (getNode (addEdgeToGraph arrayAdj 3 0 (Weight 5)) 3) == [0,1,4]
  , neighbours (getNode (addEdgeToGraph arrayEdge 3 0 (Weight 5)) 3) == [0,1,4]
  , getNode (addEdgeToGraph listAdj 4 0 (Weight 5)) 4 === (White,[(Weight 5),Infinite,Infinite,(Weight 1),(Weight 0),Infinite,Infinite])
  ]

test_whiteNeighbours =
  [ whiteNeighbours listAdj 1 == [0,6]
  , whiteNeighbours listEdge 2 == [0]
  , map (whiteNeighbours listAdj) [0..6] == map (whiteNeighbours arrayAdj) [0..6]
  , map (whiteNeighbours listEdge) [0..6] == map (whiteNeighbours arrayEdge) [0..6]
  ]

test_updateGraph =
  [ getNode (updateGraph listAdj 1 na) 1 === na
  , getNode (updateGraph listEdge 1 ne) 1 === ne
  , getNode (updateGraph arrayAdj 1 na) 1 === na
  , getNode (updateGraph arrayEdge 1 ne) 1 === ne
  ]
  where
    ne :: EdgeList
    ne = (White, [])

    na :: Adjacency
    na = (Gray,[(Weight 1),(Weight 0),Infinite,(Weight 1),(Weight 2),Infinite,(Weight 1)])
    
test_addNode =
  [ getNode (addNode listAdj) (graphSize listAdj) === (White, [Infinite,Infinite,Infinite,Infinite,Infinite,Infinite,Infinite,Weight 0])
  , graphSize (addNode (addNode listEdge)) == 9
  , getNode (addNode (addNode arrayEdge)) (graphSize arrayEdge) === (White, [])
  ]

test_getNode =
  [ getNode listAdj 1 === (Gray,[(Weight 1),(Weight 0),Infinite,(Weight 1),Infinite,Infinite,(Weight 1)])
  , map (getNode listAdj) [0..6] === map (getNode arrayAdj) [0..6]
  , getNode listEdge 3 === (Gray,[(1,(Weight 1)),(4,(Weight 1))])
  , map (getNode listEdge) [0..6] === map (getNode arrayEdge) [0..6]
  ]
  
test_graphSize =
  [ graphSize listAdj == 7
  , graphSize arrayAdj == 7
  ]
  
test_resetGraph =
  [ map getColor (resetGraph listAdj) === repeatn 7 White
  , map getColor (resetGraph listEdge) === repeatn 7 White
  , [getColor x \\ x <-: (resetGraph arrayAdj)] === repeatn 7 White
  , [getColor x \\ x <-: (resetGraph arrayEdge)] === repeatn 7 White
  ]
  
/********************NODE TESTS********************/
test_addNeighbour =
  [ addNeighbour (adj 2) 1 (Weight 3) === (White, [Infinite, Weight 3, Weight 0])
  , addNeighbour (addNeighbour (adj 2) 1 (Weight 3)) 0 (Weight 5) === (White, [Weight 5, Weight 3, Weight 0])
  , addNeighbour (edge 2) 1 (Weight 3) === (White, [(1, Weight 3)])
  , addNeighbour (addNeighbour (addNeighbour (edge 3) 2 (Weight 3)) 0 (Weight 5)) 1 (Weight 6) === (White, [(0,Weight 5),(1, Weight 6), (2, Weight 3)])
  ]
test_add =
  [ add (adj 0)  === (White, [Weight 0, Infinite])
  , add (edge 0) === edge 0
  , add (adj 2)  === (White, [Infinite, Infinite, Weight 0, Infinite])
  , add (edge 5) === edge 3
  ]

 
test_neighbours =
  [ map neighbours listAdj  === [[1],[0,3,6],[0],[1,4],[3],[2,4],[5]]
  , map neighbours listEdge === [[1],[0,3,6],[0],[1,4],[3],[2,4],[5]]
  ] 
 
test_color =
  [ color adj Gray === (Gray, [Weight 0, Infinite])
  , color adj Black === (Black, [Weight 0, Infinite])
  , color (color adj Black) White === (White, [Weight 0, Infinite])
  , color edge Black === (Black, [(1, Weight 2)])
  , color (color edge Gray) Black === (Black, [(1, Weight 2)])
  ]
  where
    adj :: Adjacency
    adj = (White, [Weight 0, Infinite])

    edge :: EdgeList
    edge = (White, [(1, Weight 2)])   
    
test_getColor =
  [ map fst listAdj === [White,Gray,Black,Gray,White,Black,White]
  , map fst listAdj === map fst listEdge
  ]

test_newNode =
  [ adj 2  === (White, [Infinite, Infinite, Weight 0])
  , adj 0  === (White, [Weight 0])
  , edge 0 === (White, [])
  ]
  

  
  where
    adj :: Int -> Adjacency
    adj x = newNode x

    edge :: Int -> EdgeList
    edge x = newNode x
