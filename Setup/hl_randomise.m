%reset(RandStream.getGlobalStream,sum(100.*clock));                          % randomise the randomiser
rand('state',sum(100*clock));                                               % set the generator to a random state