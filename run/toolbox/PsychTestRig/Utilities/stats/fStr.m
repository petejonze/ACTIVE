function str = fStr(df1,df2,F,p,r2,B)
%FIG_MAKE shortdesc.
%
%   wrapper
%
% @Requires:        <blank>
%   
% @Parameters:     	<blank> 
%
% @Example:         stats = regstats(y,x); fStr(stats.fstat.dfe, stats.fstat.f, stats.fstat.pval, stats.beta(2), stats.rsquare)
%
% @See also:        <blank>
% 
% @Author:          Pete R Jones
%
% @Creation Date:	11/10/11
% @Last Update:     14/10/11
%
% @Todo:            <blank>

    if nargin == 1
        % assume passing in a stats object, from regstats
        stats = df1;
        df1 = stats.fstat.dfr;
        df2 = stats.fstat.dfe;
        F = stats.fstat.f;
        p = stats.fstat.pval;
        r2 = stats.rsquare;
        B = stats.beta(2);
    end

    if mod(df1,1)==0 && mod(df2,1)==0
        str = sprintf('$F_{(%i,%i)} = %1.2f, %s$', df1,df2,F,pStr(p,0));
    else
        str = sprintf('$F_{(%1.2f,%1.2f)} = %1.2f, %s$', df1,df2,F,pStr(p,0));
    end
    
    if nargin > 4 && ~isempty(r2)
        str = sprintf('%s; $R^{2} = %1.2f$', str, r2);
    end
    
    if nargin > 5 && ~isempty(B)
        str = sprintf('%s; $\\beta = %1.2f$', str, B(1));
    end
    
end