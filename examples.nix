{ lib, textgen } : with lib;
with textgen.lib;
with textgen.lib.toText; rec {
  inherit lib; inherit textgen;
  inherit (textgen.lib) toText;
  # A nix expression representing a document, a "textgen"
  mydocs = {
    hi = self@{bye, ... }: {
      heading = "Hi";
      body = "Whats next? see [${bye.ref}]";
    };
    bye = self: {
      heading = "Goodbye";
      body = ''
        Did you come from [${self.hi.ref}]?
        Lets get together again soon.
        '';
    };
    ap = self: {
      heading = "Awkward Pause";
      body = ''
        Call me [${self.ap.ref}]
        '';
    };
  };
  /* reflocal = self: self.destination; */
  hiBye = evalDocs { toText = docToText; path = "/hibye";
                     } mydocs;
  hiByeAttr = evalDocsAttrs {
    __default = { toText = docToText; path = "/hibye";} ;
    ap = { toText = docToText;
           path = "/convo";
           mkRef = self: "${self.name}";
    };
  } mydocs;
  hiByeJoin = joinDocs "allHiBye" hiBye;


  examples = {
    example1 = evalDoc { toText = simpleNest;
                        name = "example1.txt"; } (docs.example1 {});
    example2 = evalDoc { toText = simpleXML;
                         name = "example2.xml"; } (docs.example2 {});
    example3 = evalDoc { toText = simpleXML;
                         name = "example3.xml"; } (docs.example3 {});
  };

  docs.example1 = {}:
    [ "- Top Level Idea"
      [ ''- Supporting idea "a"''
        ''- Supporting idea "b"''
      ]
    ];
  docs.example2 = {}: {
    elem1 = {
      attrs = {id = "e1";};
      children = {
        elem2 = { attrs = {id=2;};};
        elem3 = {
          attrs = {id=3;};
          children = self: self.no-formatting {
            elem4 = {attrs = {id="4";}; children = "elm4 child";};
            elem5 = {children = ["<x/>" "<y/>"];};
          };
        };
      };
    };
  };
  docs.example3 = {}: {
    elem1 = {
      attrs = {id = 1;};
      children = {
        elem1-1 = 1;
        elem2-2 = ''the value of this is a
                    string with a line break'';
      };
    };
    elem2 =  {
      attrs = {id = 2;};
      children = {
        elem2-1 =  { attrs = {id=2.1;};};
      };
    };
  };



  /* configdoc = rec {
    htmldochead = ''<?xml version="1.0" encoding="UTF-8"?>'';
    emanedoctype = ''<!DOCTYPE nem SYSTEM "file://share/emane/dtd/nem.dtd">'';
    nem = {
      platforms.platform = [
        { id = "1"; params = {addr=1; net="1.1";}; }
        { id = "2"; params = {addr=2; net="2.2";}; }
        ];
      definition = self: [
        htmldochead
        emanedoctype
        { nem.children = [
          {mac.attrs.definition = "self.macfile";}
          {transport.attrs.definition = "self.transfile";}
          {phy.attrs.definition = "self.phyfile";}
          ];
        }
        ];
    };
    platform = name: {params,nems}: [
        xmldochead
        emanedoctype
        { platform.children = (mapAttrsToList mkParam params)
                           ++ (mkPlatformNems name nems)
                           ; }
      ];
    mkPlatformNems = platformname: nems:
      let
        mkNemNems = nemname: value:
          let
            platformnems = attrByPath ["platforms" platformname ] [] value;
          in map (mkNems nemname) platformnems;
        mkNems = nemname: value: {
          nem.attrs.id = value.id;
          nem.attrs.definition = "nem-file";
          nem.children.transport.attrs.definition = "transport-file";
          nem.children.transport.children =
            mapAttrsToList mkParam value.params;
          };
      in concatLists (mapAttrsToList mkNemNems nems);

    mkParam = name: value: { param.attrs = { inherit name value; }; };
    mkPlatformNem = id: value:
      { nem.attrs.id = value.id;
        nem.attrs.definition = "nem-file";
        nem.children.transport.attrs.definition = "transport-file";
        nem.children.transport.children = mapAttrsToList mkParam value.params;
      };

  };

  pparams1 = {fixedant = "0.0"; bwidth="1M";};
  platform1 = platform-file "platform" {
    params = {fixedant = "0.0"; bwidth="1M";};
    nems = { inherit nem1; };
  }; */




/*  ''
<platform>
  <param name="otamanagerchannelenable" value="on"/>
  <param name="otamanagerdevice" value="eth0"/>
  <param name="otamanagergroup" value="224.1.2.8:45702"/>
  <param name="eventservicegroup" value="224.1.2.8:45703"/>
  <param name="eventservicedevice" value="eth0"/>

  <nem id="1" definition="rfpipenem.xml">
    <transport definition="transvirtual.xml">
      <param name="address" value="fd53:dc9a:f36d:4950:0:0:0:1"/>
    </transport>
  </nem>
</platform>  ''
  ]; */


  /* myxml = evalDocsAttrs {
    doc1 = {
      toText = evalIndentNesting // {
        evalAttr = eval-attr-doc1; }; };
    doc2 = {
      toText = evalIndentNesting // {
        evalAttr = eval-attr-doc2; }; };
    } xmldoc; */

  }
