function fft_analyzer

%% Window size (fraction of the screen)
wfrac=0.35;
hfrac=0.3;
%% Software owner page
lnk='https://www.linkedin.com/in/s-s-b10404211/';

%% Lists
sigL={'Sine wave','Cosine wave','Cosine wave with phase shift','Square wave','Square pulse','Gaussian pulse','Exponential decay','Chirp signal','Experimental data (t, x)'};
winL={'Rectangular (none)','Hanning','Hamming','Flat top','Blackman'};
winH={'Transients that die out inside the record (impact, free drop, hammer test); burst/periodic shaker signals.', ...
      'General purpose: steady-state, random vibration, whine noise, routine monitoring.', ...
      'Similar to Hanning, slightly different amplitude/frequency trade-off.', ...
      'Best amplitude accuracy for tones; poor frequency resolution.', ...
      'Strong side-lobe suppression (high dynamic range); wide main lobe.'};
fltL={'None','Low-pass','High-pass','Band-pass','Band-stop'};
spcL={'Amplitude (signal units) - recommended','Raw |FFT| (unscaled)'};
yL={'Linear','dB'};

%% Default values
%     Fs   t0    t1   p1    p2     p3
dv=[150   0     1    1     5      0;%sine
    150   0     1    1     5      0;%cosine
    150   0     1    1     5      60;%cosine with phase shift (deg)
    150   0     1    1     5      0;%square wave
    150  -0.5   0.5  1     0.2    0;%square pulse
     60  -0.5   0.5  0.01  0      0;%gaussian pulse
    150   0     1    2     5      0;%exponential decay
    200   0     1    0     200/6  1;%chirp
    NaN   NaN   NaN  NaN   NaN    NaN];%experimental
dl={{'Amplitude','Frequency (Hz)','--'};
    {'Amplitude','Frequency (Hz)','--'};
    {'Amplitude','Frequency (Hz)','Phase (deg)'};
    {'Amplitude','Frequency (Hz)','--'};
    {'Amplitude','Pulse width (s)','--'};
    {'Variance (s^2)','--','--'};
    {'Amplitude','Decay rate (1/s)','--'};
    {'Start freq f0 (Hz)','End freq f1 (Hz)','Time t1 of f1 (s)'};
    {'--','--','--'}};
de=[1 1 0;1 1 0;1 1 1;1 1 0;1 1 0;1 0 0;1 1 0;1 1 1;0 0 0];

%% State
S.t=[];S.x=[];S.Fs=[];S.et=[];S.ex=[];

%% Figure
sc=get(0,'ScreenSize');
fw=min(max(round(wfrac*sc(3)),800),sc(3)-40);
fh=min(max(round(hfrac*sc(4)),560),sc(4)-120);
bg=[0.94 0.94 0.94];
fig=figure('Name','FFT Analyzer','NumberTitle','off','MenuBar','none','ToolBar','figure','Units','pixels','Position',[round((sc(3)-fw)/2) round((sc(4)-fh)/2) fw fh],'Color',bg);
op=get(fig,'OuterPosition');
if op(3)>sc(3) || op(4)>sc(4)
    set(fig,'OuterPosition',[10 40 0.9*sc(3) 0.85*sc(4)]);
end
pn=uipanel('Parent',fig,'Units','normalized','Position',[0.005 0.005 0.33 0.99],'BorderType','etchedin','BackgroundColor',bg);
axT=axes('Parent',fig,'Units','normalized','Position',[0.40 0.58 0.57 0.34],'Box','on','FontSize',8);
axF=axes('Parent',fig,'Units','normalized','Position',[0.40 0.09 0.57 0.36],'Box','on','FontSize',8);

%% Control builders
tx=@(s,p) uicontrol('Parent',pn,'Style','text','Units','normalized','String',s,'Position',[p(1) p(2)-0.006 p(3) p(4)],'HorizontalAlignment','left','BackgroundColor',bg,'FontSize',8);
ed=@(s,p) uicontrol('Parent',pn,'Style','edit','Units','normalized','String',s,'Position',p,'BackgroundColor','w','FontSize',8);
pp=@(s,p) uicontrol('Parent',pn,'Style','popupmenu','Units','normalized','String',s,'Position',p,'BackgroundColor','w','FontSize',8);
pb=@(s,p) uicontrol('Parent',pn,'Style','pushbutton','Units','normalized','String',s,'Position',p,'FontSize',8);

%% Controls
rh=0.036;%row height
ys=0.047;%row step
yy=0.965-ys*(0:19);%row positions
% 1 Signal
tx('Signal',[0.03 yy(1) 0.17 rh]);
hSig=pp(sigL,[0.21 yy(1) 0.76 rh]);
% 2 Fs, t0, t1
tx('Fs',[0.03 yy(2) 0.06 rh]);hFs=ed('150',[0.10 yy(2) 0.20 rh]);
tx('t0',[0.35 yy(2) 0.06 rh]);hT0=ed('0',[0.42 yy(2) 0.19 rh]);
tx('t1',[0.66 yy(2) 0.06 rh]);hT1=ed('1',[0.73 yy(2) 0.24 rh]);
% 3-5 Parameters
hPl=gobjects(1,3);hP=gobjects(1,3);
for ii=1:3;
    hPl(ii)=tx('--',[0.03 yy(2+ii) 0.52 rh]);
    hP(ii)=ed('0',[0.57 yy(2+ii) 0.40 rh]);
end
% 6-7 Experimental data
hLoad=pb('Load file...',[0.03 yy(6) 0.45 rh]);
hEnter=pb('Enter vectors...',[0.52 yy(6) 0.45 rh]);
hData=tx('',[0.03 yy(7) 0.94 rh]);
set(hData,'FontSize',7,'ForegroundColor',[0.4 0.4 0.4]);
% 8-10 Window
tx('Window',[0.03 yy(8) 0.17 rh]);
hWin=pp(winL,[0.21 yy(8) 0.76 rh]);
set(hWin,'Value',2);
hHint=tx('',[0.03 yy(10) 0.94 yy(9)+rh-yy(10)]);
set(hHint,'FontSize',7,'ForegroundColor',[0.3 0.3 0.3]);
% 11-13 Filter
tx('Filter',[0.03 yy(11) 0.17 rh]);
hFlt=pp(fltL,[0.21 yy(11) 0.76 rh]);
tx('fc1',[0.03 yy(12) 0.08 rh]);hFc1=ed('10',[0.12 yy(12) 0.17 rh]);
tx('fc2',[0.33 yy(12) 0.08 rh]);hFc2=ed('50',[0.42 yy(12) 0.17 rh]);
tx('ord',[0.63 yy(12) 0.09 rh]);hFo=ed('4',[0.73 yy(12) 0.24 rh]);
hDC=uicontrol('Parent',pn,'Style','checkbox','Units','normalized','String','Remove DC (mean) before windowing','Position',[0.03 yy(13) 0.94 rh],'BackgroundColor',bg,'FontSize',8);
% 14-16 FFT
tx('NFFT',[0.03 yy(14) 0.13 rh]);hNfft=ed('1024',[0.17 yy(14) 0.20 rh]);
tx('Y axis',[0.42 yy(14) 0.15 rh]);hYs=pp(yL,[0.58 yy(14) 0.39 rh]);
hSpc=pp(spcL,[0.03 yy(15) 0.94 rh]);
hCalc=pb('Calculate FFT',[0.03 yy(16) 0.94 rh]);
set(hCalc,'FontSize',10,'FontWeight','bold','BackgroundColor',[0.80 0.90 1]);
% 17-19 Status
hStat=tx('',[0.03 yy(19) 0.94 yy(17)+rh-yy(19)]);
% Software owner (top right of the window)
hOwn=uicontrol('Parent',fig,'Style','pushbutton','Units','normalized','String','Software owner','Position',[0.80 0.945 0.19 0.04],'FontSize',9,'FontWeight','bold','ForegroundColor',[0 0.2 0.8],'BackgroundColor',bg,'TooltipString',lnk);

%% Callbacks
set(hSig,'Callback',@(~,~) onSignal());
set([hFs hT0 hT1 hP],'Callback',@(~,~) plotSig());
set(hWin,'Callback',@(~,~) onWin());
set(hFlt,'Callback',@(~,~) updEn());
set(hLoad,'Callback',@(~,~) onLoad());
set(hEnter,'Callback',@(~,~) onEnter());
set(hCalc,'Callback',@(~,~) onCalc());
set(hOwn,'Callback',@(~,~) web(lnk,'-browser'));

onWin();
onSignal();

%% ------------------------------------------------------------------
%  Nested functions
%% ------------------------------------------------------------------
    function onWin()
        set(hHint,'String',winH{get(hWin,'Value')});
    end

    function onSignal()
        k=get(hSig,'Value');
        if k<=8
            set(hFs,'String',num2str(dv(k,1)));
            set(hT0,'String',num2str(dv(k,2)));
            set(hT1,'String',num2str(dv(k,3)));
            for jj=1:3;
                set(hP(jj),'String',num2str(dv(k,3+jj)));
            end
            set(hData,'String','');
        else
            showExp();
        end
        updEn();
        plotSig();
    end

    function showExp()
        if isempty(S.et)
            set([hFs hT0 hT1 hP],'String','');
        else
            set(hFs,'String',sprintf('%.6g',1/mean(diff(S.et))));
            set(hT0,'String',sprintf('%.6g',S.et(1)));
            set(hT1,'String',sprintf('%.6g',S.et(end)));
            set(hP,'String','');
        end
    end

    function updEn()
        k=get(hSig,'Value');
        isE=(k==9);
        set([hFs hT0 hT1],'Enable',oo(~isE));
        for jj=1:3;
            if isE
                set(hPl(jj),'String','--');
                set(hP(jj),'Enable','off');
            else
                set(hPl(jj),'String',dl{k}{jj});
                set(hP(jj),'Enable',oo(de(k,jj)==1));
            end
        end
        set([hLoad hEnter],'Enable',oo(isE));
        if ~isE, set(hFlt,'Value',1); end
        fk=get(hFlt,'Value');
        set(hFlt,'Enable',oo(isE));
        set(hFc1,'Enable',oo(isE && fk>1));
        set(hFc2,'Enable',oo(isE && fk>3));
        set(hFo,'Enable',oo(isE && fk>1));
    end

    function setStat(msg)
        if ischar(msg), msg=regexp(msg,'\n','split'); end
        set(hStat,'String',msg);
        drawnow;
    end

%% Signal generation and time-domain plot
    function ok=buildSig()
        ok=false;
        k=get(hSig,'Value');
        if k==9
            if isempty(S.et)
                setStat('Experimental data: press "Load file..." or "Enter vectors..." first.');
                return;
            end
            S.t=S.et;S.x=S.ex;S.Fs=1/mean(diff(S.et));
            ok=true;
            return;
        end
        Fs=getnum(hFs);t0=getnum(hT0);t1=getnum(hT1);
        P=[getnum(hP(1)) getnum(hP(2)) getnum(hP(3))];
        if any(isnan([Fs t0 t1])) || Fs<=0 || t1<=t0
            setStat('Check Fs (> 0), start time and end time (end > start).');
            return;
        end
        if (t1-t0)*Fs<7
            setStat('Too few samples: increase Fs or the time span.');
            return;
        end
        if any(isnan(P(de(k,:)==1)))
            setStat('Check the signal parameters (numeric values required).');
            return;
        end
        t=(t0:1/Fs:t1)';
        p1=P(1);p2=P(2);p3=P(3);
        switch k
            case 1%sine
                x=p1*sin(2*pi*p2*t);
            case 2%cosine
                x=p1*cos(2*pi*p2*t);
            case 3%cosine with phase shift
                x=p1*cos(2*pi*p2*t+p3*pi/180);
            case 4%square wave
                x=p1*(2*(mod(2*pi*p2*t,2*pi)<pi)-1);
            case 5%square pulse centred at t=0
                if p2<=0, setStat('Pulse width must be > 0.'); return; end
                x=p1*double(t>=-p2/2 & t<p2/2);
            case 6%gaussian pulse
                if p1<=0, setStat('Variance must be > 0.'); return; end
                x=1/sqrt(2*pi*p1)*exp(-t.^2/(2*p1));
            case 7%exponential decay
                x=p1*exp(-p2*t);
            case 8%linear chirp f0 -> f1 at t1
                if p3<=0, setStat('t1 must be > 0.'); return; end
                x=cos(2*pi*(p1*t+(p2-p1)/(2*p3)*t.^2));
        end
        S.t=t;S.x=x;S.Fs=Fs;
        ok=true;
    end

    function plotSig()
        k=get(hSig,'Value');
        legend(axT,'off');
        if ~buildSig()
            cla(axT);cla(axF);
            title(axT,'');title(axF,'');
            return;
        end
        plot(axT,S.t,S.x,'b','LineWidth',1.2);
        grid(axT,'on');axis(axT,'tight');
        yl=ylim(axT);pad=0.08*max(yl(2)-yl(1),eps);
        ylim(axT,[yl(1)-pad yl(2)+pad]);
        title(axT,[sigL{k} ' - time domain']);
        xlabel(axT,'Time (s)');ylabel(axT,'Amplitude');
        cla(axF);
        title(axF,'FFT - choose window / filter, then press "Calculate FFT"');
        xlabel(axF,'Frequency (Hz)');ylabel(axF,'Magnitude');grid(axF,'on');
        setStat('Signal plotted. Choose a window (and filter), then press "Calculate FFT".');
    end

%% Experimental data input
    function onLoad()
        [fn,pth]=uigetfile({'*.csv;*.txt;*.dat;*.xlsx;*.xls','Data files (*.csv, *.txt, *.dat, *.xlsx, *.xls)';'*.*','All files'},'Select data file (column 1 = time, column 2 = amplitude)');
        if isequal(fn,0), return; end
        fp=fullfile(pth,fn);
        try
            try
                M=readmatrix(fp);
            catch
                D=importdata(fp);
                if isstruct(D), M=D.data; else, M=D; end
            end
            if size(M,2)<2
                error('The file needs at least two numeric columns (time, amplitude).');
            end
            M=M(:,1:2);
            M(any(isnan(M),2),:)=[];
            setExp(M(:,1),M(:,2),fn);
        catch err
            setStat(['Could not load file: ' err.message]);
        end
    end

    function onEnter()
        ans_=inputdlg({'Time vector (e.g. [0 0.01 0.02 ...] or a base-workspace variable name):','Amplitude vector (same length):'},'Enter experimental data',[1 70;1 70],{'',''});
        if isempty(ans_), return; end
        try
            tv=evalin('base',ans_{1});
            xv=evalin('base',ans_{2});
            if ~isnumeric(tv) || ~isnumeric(xv)
                error('Both entries must evaluate to numeric vectors.');
            end
            setExp(tv,xv,'Entered vectors');
        catch err
            setStat(['Could not use the entered vectors: ' err.message]);
        end
    end

    function setExp(tv,xv,src)
        tv=double(tv(:));xv=double(xv(:));
        if numel(tv)~=numel(xv)
            error('Time and amplitude vectors must have the same length.');
        end
        if numel(tv)<8
            error('At least 8 samples are required.');
        end
        [tv,iu]=unique(tv);%sorts and removes duplicate times
        xv=xv(iu);
        dtv=diff(tv);
        msg='';
        if (max(dtv)-min(dtv))>1e-3*mean(dtv)
            tu=linspace(tv(1),tv(end),numel(tv))';
            xv=interp1(tv,xv,tu,'linear');
            tv=tu;
            msg=' (non-uniform time vector resampled to a uniform grid)';
        end
        S.et=tv;S.ex=xv;
        showExp();
        set(hData,'String',sprintf('%s: %d samples, Fs = %.4g Hz%s',src,numel(tv),1/mean(diff(tv)),msg));
        plotSig();
    end

%% FFT calculation
    function onCalc()
        try
            doCalc();
        catch err
            setStat(['Error: ' err.message]);
        end
    end

    function doCalc()
        if ~buildSig(), return; end
        k=get(hSig,'Value');
        wk=get(hWin,'Value');
        fk=get(hFlt,'Value');
        t=S.t(:);x=S.x(:);N=numel(x);Fs=S.Fs;
        note='';
        % filter (experimental data only)
        xf=x;
        if k==9 && fk>1
            fc1=getnum(hFc1);fc2=getnum(hFc2);ord=round(getnum(hFo));
            if isnan(ord) || ord<1, ord=4; set(hFo,'String','4'); end
            if isnan(fc1) || fc1<=0 || fc1>=Fs/2
                setStat(sprintf('Cutoff 1 must be between 0 and Fs/2 = %.4g Hz.',Fs/2));
                return;
            end
            if fk>=4 && (isnan(fc2) || fc2<=fc1 || fc2>=Fs/2)
                setStat('Cutoff 2 must be larger than cutoff 1 and below Fs/2.');
                return;
            end
            xf=zpFilt(x,Fs,fk,fc1,fc2,ord);
        end
        if get(hDC,'Value')==1
            xf=xf-mean(xf);
        end
        % window
        w=makeWin(wk,N);
        xw=xf.*w;
        % FFT
        nfft=round(getnum(hNfft));
        if isnan(nfft) || nfft<N
            nfft=2^nextpow2(N);
            set(hNfft,'String',num2str(nfft));
            note=sprintf(' NFFT set to %d (must be >= number of samples).',nfft);
        end
        X=fft(xw,nfft);
        K=floor(nfft/2)+1;
        f=(0:K-1)'*Fs/nfft;
        mx=abs(X(1:K));
        if get(hSpc,'Value')==1%single-sided amplitude, window-gain corrected
            mx=mx/sum(w);
            if mod(nfft,2)==0, id=2:K-1; else, id=2:K; end
            mx(id)=2*mx(id);
            ylab='Amplitude (signal units)';
        else
            ylab='Raw |FFT| (unscaled)';
        end
        [pk,ip]=max(mx);
        if get(hYs,'Value')==2
            mxp=20*log10(max(mx,max(max(mx)*1e-10,eps)));
            ylab=[ylab ' (dB)'];
        else
            mxp=mx;
        end
        % time-domain plot: original / filtered / windowed
        legend(axT,'off');
        cla(axT);hold(axT,'on');
        hs=plot(axT,t,x,'Color',[0.65 0.80 0.95],'LineWidth',1.2);
        lb={'Original'};
        if any(xf~=x)
            hs(end+1)=plot(axT,t,xf,'b','LineWidth',1.0);
            lb{end+1}='Filtered / DC removed';
        end
        hs(end+1)=plot(axT,t,xw,'r','LineWidth',1.0);
        lb{end+1}=['Windowed (' winL{wk} ')'];
        hold(axT,'off');
        grid(axT,'on');axis(axT,'tight');
        legend(axT,hs,lb,'Location','best');
        title(axT,[sigL{k} ' - time domain']);
        xlabel(axT,'Time (s)');ylabel(axT,'Amplitude');
        % spectrum plot
        cla(axF);
        plot(axF,f,mxp,'b','LineWidth',1.1);
        grid(axF,'on');
        xlim(axF,[0 Fs/2]);
        title(axF,sprintf('FFT of %s  |  window: %s',sigL{k},winL{wk}));
        xlabel(axF,'Frequency (Hz)');ylabel(axF,ylab);
        % status: resolution / bandwidth (BW = R x WF)
        R=Fs/N;
        WF=N*sum(w.^2)/sum(w)^2;
        sn='';
        if get(hSpc,'Value')==2
            sn=sprintf('\nRaw |FFT| = amplitude x %.4g  (= sum(w)/2, for a tone)',sum(w)/2);
        end
        setStat(sprintf(['N=%d, Fs=%.4g Hz, NFFT=%d\nR=Fs/N=%.4g Hz, WF=%.2f, BW=%.4g Hz\nLargest peak: %.4g at %.4g Hz.%s%s'],N,Fs,nfft,R,WF,R*WF,pk,f(ip),sn,note));
    end

end

%% ------------------------------------------------------------------
%  Local functions
%% ------------------------------------------------------------------
function v=getnum(h)
v=str2double(get(h,'String'));
end

function s=oo(tf)
if tf, s='on'; else, s='off'; end
end

function w=makeWin(kind,N)
% periodic windows (suited to spectral analysis)
n=(0:N-1)';
switch kind
    case 1%rectangular
        w=ones(N,1);
    case 2%hanning
        w=0.5-0.5*cos(2*pi*n/N);
    case 3%hamming
        w=0.54-0.46*cos(2*pi*n/N);
    case 4%flat top
        a=[0.21557895 0.41663158 0.277263158 0.083578947 0.006947368];
        w=a(1)-a(2)*cos(2*pi*n/N)+a(3)*cos(4*pi*n/N)-a(4)*cos(6*pi*n/N)+a(5)*cos(8*pi*n/N);
    case 5%blackman
        w=0.42-0.5*cos(2*pi*n/N)+0.08*cos(4*pi*n/N);
end
end

function yo=zpFilt(x,Fs,kind,fc1,fc2,ord)
% zero-phase Butterworth-shaped filter applied in the frequency domain
% kind: 2 low-pass, 3 high-pass, 4 band-pass, 5 band-stop
% the record is extended by odd reflection at both ends to reduce edge effects
x=x(:);
N=numel(x);
npad=min(N-1,floor(N/2));
xe=[2*x(1)-x(npad+1:-1:2);x;2*x(end)-x(end-1:-1:end-npad)];
M=numel(xe);
f=(0:M-1)'*Fs/M;
f=min(f,Fs-f);%fold to 0..Fs/2
lp=@(fc) 1./sqrt(1+(f/fc).^(2*ord));
hp=@(fc) 1./sqrt(1+(fc./max(f,eps)).^(2*ord));
switch kind
    case 2, H=lp(fc1);
    case 3, H=hp(fc1);
    case 4, H=hp(fc1).*lp(fc2);
    case 5, H=1-hp(fc1).*lp(fc2);
    otherwise, H=ones(M,1);
end
ye=real(ifft(fft(xe).*H));
yo=ye(npad+1:npad+N);
end
