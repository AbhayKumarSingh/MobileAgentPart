%
%
%		Master Control
%		++++++++++++++
%
%	Description: This Master controls the generation and setup of the network. 
%                  It can start an agent from any node in the network and also
%			 the pheromone can be generated from any node.

:-ensure_loaded(system(chimera)).

 
% This is the master agent which communicates with all the nodes in the network
start_master:-
	P = 15190,
	agent_create(master,master_handler,P),
	write(`~M~JMaster Agent is created at Port`:P),!.

start_master:- write(`~M~JError in Create Master Agent`).

% To kill prolog instances throughout the network.
kill_throughout_network:-
			exec('runClient.bat','2',_),
			delay( 10000 ),
		!.

% network control manages the genration and termination of the nodes in different
% PCs (IPs)
start_network_control:-
			exec('runClient.bat','',_),
		!.

% gen_network  Generates the network topology based on the number of nodes and IPs
gen_network:-
			exec('runGenNet.bat','',_),
			!.

% net_files Generates a list of network files in the network dorectory.
net_files:-
		exec('runNetfiles.bat','',_),
			!.

% induce_network starts the creation of nodes in each IP address
induce_network:-
	network_ips(TM_List),
	forall(
			(member(Mem,TM_List)),		
			(
				[Host] = Mem,
				agent_create(master,L,Host,15000),
				config_file(File), nl,write(File),
				agent_post(master,L,exec_sol(consult(File))),
				delay(250),
				agent_post(master,L,exec_sol(node_ip(Host))),
				agent_post(master,L,exec_sol(load_config)),
				agent_post(master,L,exec_sol((agent_create(taskmanager,NewL,`172.16.117.121`,15190),agent_post(taskmanager,NewL,load_over(node))))),
				write(`~M~JNetwork induced at the host (IP)`:Host)
			)
		),!.

induce_network2:-
	network_ips(TM_List),
	forall(
			(member(Mem,TM_List)),		
			(
				[Host] = Mem,
				agent_create(master,L,Host,15000),
				config_file(File), nl,write(File),
				agent_post(master,L,exec_sol(consult(File))),
				delay(250),
				agent_post(master,L,exec_sol(node_ip(Host))),
				agent_post(master,L,exec_sol(load_config)),
				agent_post(master,L,exec_sol(halt)),
				write(`~M~JNetwork induced at the host (IP)`:Host)
			)
		),!.

master_handler(Name,Link,load_over(node)):-
	write(`~M~JChangeing Status`),
	network_ips(TM_List),
	length(TM_List,Len),
	Slice is 100/Len,
	Step is int(Slice)+1,
	set_progress(Step),
	agent_post(Name,Link,exec_sol(halt)).

% induce_pheromones induces pheromones with specified parameters in the specified nodes
induce_pheromones:-
	grid_induce_pheros(TM_List),
	forall(
			member(Mem,TM_List),		
			(
				[Host,Port] = Mem,
				agent_create(master,L,Host,Port),
				agent_post(master,L,exec_sol(pheromone_generate(1,100,100,3))),
				write(`~M~JPheromone induced at node on Port`:Port)
			)
		),!.

% =================================================================

initialize_initial_values:-
	grid_induce_pheros(TM_List),
	forall(
			member(Mem,TM_List),		
			(
				[Host,Port] = Mem,
				agent_create(master,L,Host,Port),
				agent_post(master,L,exec_sol(initial_config)),
				%agent_post(master,L,exec_sol(spy(help_move_typhlet/1))),
				write(`~M~Jinitialize_initial_values induced at node on Port`:Port)
			)
		),!.

start_handler( Name, Status ):-
	start_experiment.

start_experiment:-
	consult( 'events.pl' ),
	consult( 'task_manager.pl' ),
	clock_start.

clock_start:-
	retractall(thingstobedone(_)),
	assert(thingstobedone([])),
	retractall(pos(_)),
	assert(pos(0)),
	retractall(prevInst(_)),
	assert(prevInst(0)),
	time(1,CurrentTime),time(0,CurrentTimeSession),
	write(CurrentTime),
	timer_create( fire, fire_handler),
	fire_handler(fire,CurrentTimeSession).
	/*events(List),
	timer_create(fire, fire_handler),
	forall(
		member(X,List),
		(
			(EventTime,Tasks) = X,
			retractall(thingstobedone(_)),
			assert(thingstobedone(Tasks)),
			timer_set(fire,),

		)
	)*/


clause(fire_handler/2).
fire_handler(Name,Status):-
	%code to fire writes
	%set new clock time
	thingstobedone(ThingsList),
	node_table( List1 ),
	forall(
		member(X,ThingsList),
		action(X, List1 )
	),
	events(List),
	pos(Pos),
	NewPos is Pos +1,
	member(EventInstanceInfo,List,NewPos),
	(EventInstance,NewToDo)= EventInstanceInfo,
	prevInst(PrevInstance),
	TimeToFire is EventInstance - PrevInstance,
	retractall(prevInst(_)),
	assert(prevInst(EventInstance)),
	retractall(thingstobedone(_)),
	assert(thingstobedone(NewToDo)),
	retractall(pos(_)),
	assert(pos(NewPos)),
	Status = (_,Count),
	timer_set(Name,(TimeToFire,Count)).

action(( init, _, _, _ ), _ ):-
	initialize_initial_values,
	( write( `Initialized values` ) ) ~> Avar,
	send_log( Avar ).

% The following case may be for future use
action(( sol, Node, Type, Data ), List ):-
	member([ Node, IP, _, TaskMPort, _, _ ], List ),

	agent_create( master, L, IP, TaskMPort ),
	agent_post( master, L, assertSolution( Type, Data ) ).

% The following has been modified from flooding counterpart
action((prob, Node, Type, _ ), List):-
	member([ Node, IP, _, TaskMPort, _, _ ], List ),

	agent_create( master, PL, IP, TaskMPort ),
	agent_post( master, PL, assertProblem( Type ) ).
	%agent_post( master, PL, exec_sol( consult( 'initiation.pl' ) ) ),
	%agent_post( master, PL, exec_sol( start_exe ) ).
	
action(( startagent, Node, Type, Data ), List ):-
	member([ Node, IP, _, TaskMPort, _, _ ], List ),
	agent_create( master, PL, IP, TaskMPort ),
	agent_post(master,PL,exec_sol(consult( 'initiation.pl' ))),
	agent_post(master,PL,exec_sol( start_exe( Type, Data ))).

action(( end, _, _, _ ), _ ):-
	( write( `End of Experiment` ) ) ~> Avar,
	send_log( Avar ),
	delay( 3000 ),
	kill_throughout_network,
	exec('C:\Windows\System32\taskkill.exe', '/F /IM PRO386W.EXE /T', _).
	% more to be done later.
	
start_agent( Node, Type, Data ):-
	node_table( List ),
	action(( startagent, Node, Type, Data ), List ).

% =================================================================
% induce_agents induces agents at the specified nodes in the network
induce_agents(File,Pred):-
		grid_spawn_agent(List),
		length(List,Len),
		Slice is 100/Len,
		Step is int(Slice)+1,

		forall(
			member(Mem,List),		
			(
				[Host,Port] = Mem,
				agent_create(master,L,Host,Port),
				agent_post(master,L,exec_sol(consult(File))),
				agent_post(master,L,exec_sol(Pred)),
				agent_status_progress(Step),
				write(`~M~JAgent induced at node on Port`:Host:Port)
			)
		),
		!.

% sweep_pheromone clears out the pheromones in the network
sweep_pheromone:-
	grid_induce_pheros(TM_List),
	forall(
			member(Mem,TM_List),		
			(
				[Host,Port] = Mem,
				agent_create(master,L,Host,Port),
				agent_post(master,L,pheromone_clear(_,_)),
				write(`~M~JPheromone induced at node on Port`:Port)
			)
		),!.
%delay/1 to provide a delay routine
delay(T):- ms(repeat,M),M>T,!.




