%
%
%		Initiation
%		=-=-=-=-=-=
%
%	This file is consulted in each of the platforms and carry out 
%	the initiation procedures before starting an agent
%     The Extra payloads mentioned in "Payload.pl" in to be added here.

start_exe( Type, Data ):-
		platform_assert_file('agent_cons.pl'),  % asserts the agent on this platform
		%spy cons_handler/3,
		create_cons_agent(G,Pr),			% creation of a phercon agent as mentioned in "agent_phercon.pl"
		% platform_assert_file('payload.pl'),		% asserts the payloads 
		% add_payload(G,[(task_info,3),(ex1_task,1)]),	% attached the payloads onto the agent
		%retractall( visited_nodes( G, _ )),
		%assert( visited_nodes( G, [n0] )),
		retractall( solution( G, _, _ )),
		assert( solution( G, Type, Data )),
		agent_post(G,[],migration(GUID,P)),			% Starts the agent to move on
		write(`~M~JAgent Moved Away!!!`),!.





