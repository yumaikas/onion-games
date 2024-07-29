: cell-mid ( x y -- x' y' ) [ 8 * 4 + ] 8 * 4 + ;
: bt? { p v -- fn } p 1 - 8 * v + btn(*\*) ; 
: bt (**\*) bt? 1 0 ? ;
: B_U (*\*) 0 bt ; : B_D (*\*) 1 bt ;
: B_L (*\*) 2 bt ; : B_R (*\*) 3 bt ;
: B_A? (*\*) 4 bt? ; : B_B? (*\*) 5 bt? ;
: B_X? (*\*) 6 bt? ; : B_Y? (*\*) 7 bt? ;
behaves keyp (*\*)
