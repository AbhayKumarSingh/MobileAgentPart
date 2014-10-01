
:-ensure_loaded(system(chimera)).


:- dynamic visited_nodes/2. % This predicate keeps a list of visited nodes by the agent.
:- dynamic solution/3.


%%
%	Create Cons Agent 
%%
clause(create_cons_agent/2).
create_cons_agent(GUID,P):-
	typhlet_create( GUID, cons_handler, P),
	add_payload(GUID,[(visited_nodes,2),( solution, 3 )]). 
	
%------------------------------- Create Agent End ------------------------

%%
%	Conscientious Agent Migration
%%
clause(migrate_cons_agent/1).
migrate_cons_agent(GUID):-
	agent_post(GUID,[],migration(GUID,P)). 
	
%------------------------------- Agent Migration End ------------------------

%%
%	Phercon Agent Handler
%%

% cons_handler/3 comments to be added

clause(cons_handler/3).
cons_handler(guid,Link,migration(GUID,P)):-
	
	( write( `Intranode Calculation` )) ~> IntraCal,
	send_log( IntraCal ),
	node_info(Nodenm,_,_),
	solution( guid, SolType, _ ),
	(problemOnCurrentNode( SolType ) ->
		(
			retract( problemOnCurrentNode( SolType )),
			assert( problemOnCurrentNode( none )),
			( write( `Solution received at,` ), write( Nodenm ), write( `,Currentnode:,` ), write( Nodenm ), write( `,` ), write( SolType )) ~> Var1,
			send_log( Var1 )
		)
	;
		(
			true
		)
	),
	%write(`~M~JGoing for Cons Move`),
	neighbour_list(NList),
	visited_nodes(guid,VList),
		
	%write(`~M~J Log Sent`),
	(is_sub_list(VList,NList,N)->
		(
				%write(`~M~JNormal Migration mode`),
				append(VList,[N],NewList),
				retractall(visited_nodes(guid,_)),
				assert(visited_nodes(guid,NewList)),
				neighbors(N,IP,Port,_,_),
				/*(
					write(Nodenm),write(','),
					write(guid),
					%write(` ,|Type,`),write(T),
					write(` ,|Current node,`),write(Nodenm),
					write(` ,|NewList,`),write(NewList)
				)~> Ss,*/
				%write(Ss),
				%send_log(Ss),
				%nl,write(IP:Port),
				%connect(IP,Port,Link1),
				%nl,write(`Link`:Link),
				%move_typhlet(guid,Link1)
				%nl,write(`Link`:Link)
				move_typhlet(guid,IP,Port),
				( write( `Packet sent from,`), write( Nodenm ), write( `,to,` ), write( N )) ~> Ss1,
				send_log( Ss1 )

		);
		(
				%write(`~M~JRepeated Migration mode`),
				neighbour_list(NList),
				visited_nodes(guid,VList),
				%write(NList:VList),
				find_least_node(VList,NList,X),
				%write(`~M~JFind Least`:X),
				remove(X,VList,RList),
				append(RList,[X],NewList),
				%agent_type(guid,T),
				node_info(Myname,_,_),

				/*(
					write(Myname),write(','),
					write(guid),
					%write(` ,|Type,`),write(T),
					write(` ,|Current node,`),write(Myname),
					write(` ,|NewList,`),write(NewList)
				)~> Ss,*/
				%write(Ss),
				%send_log(Ss),
				retractall(visited_nodes(guid,_)),
				assert(visited_nodes(guid,NewList)),
				neighbors(X,IP,Port,_,_),
				%connect( IP, Port, LinkToGo ),
				move_typhlet(guid,IP,Port),
				( write( `Packet sent from,`), write( Nodenm ), write( `,to,` ), write( X )) ~> Ss2,
				send_log( Ss2 )
				%move_typhlet( guid, LinkToGo )
		)
	),
	!.	
		
%------------------------------- Agent Handler End ------------------------

%%
%	Cons Agent Payload
%%


clause(visited_nodes/2).    
visited_nodes(guid,[]).

clause(solution/3).
solution( guid, none, -1 ).

%------------------------------- Agent Payload End -------------------------------------


