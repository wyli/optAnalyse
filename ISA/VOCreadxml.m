function rec = VOCreadxml(path)
f=fopen(path,'r');
xml=fread(f,'*char')';
fclose(f);
rec=VOCxml2struct(xml);
end
