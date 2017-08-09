module(...,package.seeall)--���г���ɼ�

--[[��demo�ṩ���ֽӿڣ���һ��readfile(filename)���ļ����ڶ���writevala(filename,value)��д�ļ����ݣ�����ģʽ��
������function writevalw(filename,value)��д�ļ����ݣ�����ģʽ��������deletefile(filename)��ɾ���ļ���--]]

--[[
    ��������readfile(filename)
	���ܣ����������ļ������ļ�����������������������
	�������ļ���
	����ֵ����                     ]]
local function readfile(filename)--��ָ���ļ����������
	
    local filehandle=io.open(filename,"r")--��һ���������ļ������ڶ����Ǵ򿪷�ʽ��'r'��ģʽ,'w'дģʽ�������ݽ��и���,'a'����ģʽ,'b'����ģʽ�����ʾ�Զ�������ʽ��
	if filehandle then          --�ж��ļ��Ƿ����
	    local fileval=filehandle:read("*all")--�����ļ�����
	  if  fileval  then
	       print(fileval)  --����ļ����ڣ���ӡ�ļ�����
		   filehandle:close()--�ر��ļ�
	  else 
	       print("�ļ�Ϊ��")--�ļ�������
	  end
	else 
	    print("�ļ������ڻ��ļ������ʽ����ȷ") --��ʧ��  
	end 
	
end



--[[
    �������� writevala(filename,value)
	���ܣ���������ļ���������ݣ����ݸ�����ԭ�ļ�����֮��
	��������һ���ļ������ڶ�����Ҫ��ӵ�����
	����ֵ����                         --]]
local function writevala(filename,value)--��ָ���ļ����������,���������һλ���Ǵ򿪵�ģʽ
	local filehandle = io.open(filename,"a+")--��һ���������ļ�������һ���Ǵ�ģʽ'r'��ģʽ,'w'дģʽ�������ݽ��и���,'a'����ģʽ,'b'����ģʽ�����ʾ�Զ�������ʽ��
	if filehandle then
	    filehandle:write(value)--д��Ҫд�������
	    filehandle:close()
	else
	    print("�ļ������ڻ��ļ������ʽ����ȷ") --��ʧ��  
	end
end



--[[
    ��������writevalw(filename,value)
	���ܣ��������ļ���������ݣ�����ӵ����ݻḲ�ǵ�ԭ�ļ��е�����
	������ͬ��
	����ֵ����                 --]]
local function writevalw(filename,value)--��ָ���ļ����������
	local filehandle = io.open(filename,"w")--��һ���������ļ�������һ���Ǵ�ģʽ'r'��ģʽ,'w'дģʽ�������ݽ��и���,'a'����ģʽ,'b'����ģʽ�����ʾ�Զ�������ʽ��
	if filehandle then
	    filehandle:write(value)--д��Ҫд�������
	    filehandle:close()
	else
	    print("�ļ������ڻ��ļ������ʽ����ȷ") --��ʧ��  
	end
end


--[[��������deletefile(filename)
    ���ܣ�ɾ��ָ���ļ��е���������
	�������ļ���
	����ֵ����             --]]
local function deletefile(filename)--ɾ��ָ���ļ����е���������
	local filehandle = io.open(filename,"w")
	if filehandle then
	    filehandle:write()--д��յ�����
	    print("ɾ���ɹ�")
		filehandle:close()
	else
	    print("�ļ������ڻ��ļ������ʽ����ȷ") --��ʧ��  
	end
end



readfile("/3.txt")

writevala("/3.txt","great")

readfile("/3.txt")
writevalw("/3.txt","great")
readfile("/3.txt")

deletefile("/3.txt")
readfile("/3.txt")
