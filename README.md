# delft3d_subsidence
delft3d setup incl. subsidence, see Nienhuis, Tornqvist, Esposito, 2018: doi.org/10.1029/2018GL077933


The main function is: "run_series_of_models.m". From this function the user can simulate the development of a sediment diversion / crevasse splay.
The function calls a delft3d model (described inside the "input" folder) that is looped iteratively w/ subsidence and vegetation dynamics described in matlab ("consolidation_model").
