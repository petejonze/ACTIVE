function str = pStr(p, isLatex)
%FIG_MAKE shortdesc.
%
%   wrapper
%
% @Requires:        <blank>
%   
% @Parameters:     	<blank> 
%
% @Example:         <blank>
%
% @See also:        <blank>
% 
% @Author:          Pete R Jones
%
% @Creation Date:	11/10/11
% @Last Update:     14/10/11
%
% @Todo:            <blank>

    if nargin < 2 || isempty(isLatex)
        isLatex = true;
    end

    
    
%     str = str(2:end); % remove leading zero
% 
%     if strcmpi(str, '.000')
%         str = 'p<.001';
%     else
%         str = ['p=' str];
%     end
%     if isLatex
%      	str = sprintf('$%s$',str);
%     end

    if p < 0.001
        str = 'p{<}0.001';
    elseif p > 0.999
        str = 'p{>}0.999';
    else
        %p = round(p*1000)/1000;
        str = sprintf('p{=}%1.3f',p);
    end
    if isLatex
     	str = sprintf('$%s$',str);
    end

end