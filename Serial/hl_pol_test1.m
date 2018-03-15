% test polhemus
hl_pol_initialise;
samples=1;
test_data=zeros(samples, pol.data_len+3, pol.receivers);
t1=clock;
for s=1:samples
    hl_pol_read_point;
    t=clock;
    for r=1:pol.receivers
        test_data(s,1:pol.data_len,r)=pol.data(r,:);
        test_data(s,pol.data_len+1:end,r)=t(4:6);
    end
end
t2=clock;
time=t2-t1;
time(6)
hl_pol_close;