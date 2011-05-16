#!/usr/bin/env python

"""Parse a .gir file for any of the gtk+ libraries (gtk+, glib,...)
   and generate Ada bindings.
"""

# Issues:
#   - Missing access to gtk+ enum types
#   - Missing handling of interfaces
#   - Some comments contain xref like "#GtkMisc". Not sure what to do with
#     those. Likewise for names of subprograms in comments.
#
# Backward incompatibility:
#   - Missing documentation for some properties.
#     SOLVE: we could point to the corresponding Set_* and Get_* subprograms,
#            or simply ignore the missing doc
#
#   - Gtk.Button.Gtk_New used to have a "Label" parameter
#     Users must now use Gtk_New_With_Label.
#     SOLVE: we could have special cases

from xml.etree.cElementTree import parse, QName, tostring
from adaformat import *
from binding_gtkada import GtkAda

uri = "http://www.gtk.org/introspection/core/1.0"
glib_uri = "http://www.gtk.org/introspection/glib/1.0"
c_uri = "http://www.gtk.org/introspection/c/1.0"

namespace = QName(uri, "namespace").text
nvarargs = QName(uri, "varargs").text
ntype = QName(uri, "type").text
ctype = QName(c_uri, "type").text
cidentifier = QName(c_uri, "identifier").text
ggettype = QName(glib_uri, "get-type").text
gsignal = QName(glib_uri, "signal").text
narray = QName(uri, "array").text
ndoc = QName(uri, "doc").text
nmethod = QName(uri, "method").text
nparam = QName(uri, "parameter").text
nparams = QName(uri, "parameters").text
nreturn = QName(uri, "return-value").text

class GIR(object):
    def __init__(self, filename):
        """Parse filename and initializes SELF"""
        self._tree = parse(filename)
        self.root = self._tree.getroot()
        self.namespace = self.root.find(namespace).get("name")

        self.packages = dict()

        self._classes = dict()
        k = "{%(uri)s}namespace/{%(uri)s}class" % {"uri":uri}
        for cl in self.root.findall(k):
            self._classes[cl.get("name")] = GIRClass(self, cl)

    def getClass(self, className):
        """Return the Element corresponding to the given class"""
        return self._classes[className]

    def all_classes(self):
        """Iter over all classes"""
        return self._classes.iteritems()

    def debug(self, element):
        """A debug form of element"""
        return tostring(element)

    def get_package(self, name):
        """Return a handle to an Ada package"""
        if not name.lower() in self.packages:
            self.packages[name.lower()] = Package(
                name=name,
                doc=gtkada.get_pkg(name).get_doc())
        return self.packages[name.lower()]

    def generate(self, out):
        """Generate Ada code for all packages"""
        for k in sorted(self.packages.keys()):
            pkg = self.packages[k]
            pkg.spec(out)
            out.write("\n")
            pkg.body(out)
            out.write("\n")


class GIRClass(object):
    """Represents a gtk class"""

    def __init__(self, gir, node):
        self.gir = gir
        self.node = node

        self._subst = {
            "ns": self.gir.namespace,
            "parent": AdaNaming.case(self.node.get("parent")),
            "name": AdaNaming.case(self.node.get("name"))}

        self._private = ""

    def _parameters(self, c, gtkmethod):
        """Format the parameters for the node C by looking at the <parameters>
           child.
           Returns None if the parameter list could not be parsed.
           gtkmethod is the GtkAdaMethod that contains the overriding for the
           various method attributes.
        """
        if c is None:
            return []

        params = c.find(nparams)
        if params is None:
            return []
        result = []

        for p in params.findall(nparam):
            name = p.get("name")
            gtkparam = gtkmethod.get_param(name=name)

            type = self._get_type(p)

            if type is None:
                return None

            if type.is_ptr:
                mode = "out"
            else:
                mode = "in"

            doc = p.findtext(ndoc, "")
            if doc:
                doc = '"%s": %s' % (name, doc)

            result.append(
                Parameter(name=AdaNaming.case(name),
                          type=type,
                          mode=mode,
                          default=gtkparam.get_default(),
                          doc=doc))

        return result

    def _c_plist(self, plist):
        """Converts a list of parameters from Ada to C types.
           This also removes the documentation for the parameters
        """
        result = []
        for p in plist:
            result.append(
                Parameter(
                    name=p.name,
                    mode=p.mode,
                    type=p.type))

        return result;

    def _constructors(self):
        section = self.pkg.section("Constructors")

        n = QName(uri, "constructor").text
        for c in self.node.findall(n):
            name = c.get("name").title()
            cname = c.get(cidentifier)

            gtkmethod = self.gtkpkg.get_method(cname=cname)
            if not gtkmethod.bind():
                continue

            params = self._parameters(c, gtkmethod)
            if params is None:
                print "No binding for %s: varargs" % cname
                continue

            format_params = ", ".join(p.name for p in params)
            if format_params:
                self._subst["internal_params"] = " (%s)" % format_params
                format_params = ", " + format_params
                self._subst["params"] = format_params
            else:
                self._subst["params"] = ""
                self._subst["internal_params"] = ""

            internal = Subprogram(
                name="Internal",
                plist=self._c_plist(params),
                returns="System.Address").import_c(cname)
            call = internal.call(add_return=False)  # A VariableCall

            adaname = gtkmethod.ada_name() or "Gtk_%s" % name

            initialize_params = [Parameter(
                name="Self",
                type="%(ns)s_%(name)s_Record'Class" % self._subst,
                mode="access")] + params
            initialize = Subprogram(
                name=adaname.replace("Gtk_New", "Initialize"),
                plist=initialize_params,
                local_vars=call.tmpvars,
                code="%sSet_Object (Self, %s);%s" %
                    (call.precall, call.call, call.postcall)
                ).add_nested(internal)
            call = initialize.call(in_pkg=self.pkg)

            gtk_new = Subprogram(
                name=adaname,
                plist=[Parameter(
                    name="Self",
                    type="%(ns)s_%(name)s" % self._subst,
                    mode="out")] + params,
                local_vars=call.tmpvars,
                code="Self := new %(ns)s_%(name)s_Record;" % self._subst
                   + call.precall + call.call + call.postcall,
                doc=c.findtext(ndoc, ""))

            section.add(gtk_new, initialize)

    def _methods(self):
        section = self.pkg.section("Methods")

        n = self.node.findall(nmethod)
        for c in n:
            returns = self._get_type(c.find(nreturn)).as_return()
            cname = c.get(cidentifier)

            gtkmethod = self.gtkpkg.get_method(cname=cname)
            if not gtkmethod.bind():
                continue

            params = self._parameters(c, gtkmethod)
            if params is None:
                print "No binding for %s: varargs" % cname
                continue

            doc = c.findtext(ndoc, "")

            params = [
                Parameter(
                    name="Self",
                    type=AdaType(
                        adatype="access %(ns)s_%(name)s_Record" % self._subst,
                        ctype="System.Address",
                        convert="Get_Object (%s)"))
                ] + params

            internal=Subprogram(
                name="Internal",
                returns=returns,
                plist=self._c_plist(params)).import_c(cname)

            code = internal.call()  # A VariableCall

            subp = Subprogram(
                    name=gtkmethod.ada_name() or c.get("name").title(),
                    plist=params,
                    returns=returns,
                    doc=doc,
                    local_vars=code.tmpvars,
                    code="%s%s%s" % (code.precall, code.call, code.postcall)
                ).add_nested(internal)

            depr = c.get("deprecated")
            if depr is not None:
                subp.mark_deprecated(
                    "\nDeprecated since %s, use %s"
                    % (c.get("deprecated-version"), depr))

            section.add(subp)

    def _method_get_type(self):
        n = self.node.get(ggettype)
        if n is not None:
            section = self.pkg.section("Constructors")

            gtkmethod = self.gtkpkg.get_method(cname=n)
            if not gtkmethod.bind():
                return

            self.pkg.add_with("Glib")
            section.add(
                Subprogram(
                    name=gtkmethod.ada_name() or "Get_Type",
                    returns="Glib.GType")
                .import_c(n))

    def _get_type(self, node):
        """Return the type of the node"""
        t = node.find(ntype)
        if t is not None:
            return CType(name=t.get("name"), cname=t.get(ctype), pkg=self.pkg)

        a = node.find(narray)
        if a is not None:
            t = a.find(ntype)
            if a:
                type = t.get(ctype)
                name = t.get("name") or type  # Sometimes name is not set
                return CType(name=name, cname=type, pkg=self.pkg, isArray=True)

        a = node.find(nvarargs)
        if a is not None:
            # A function with multiple arguments cannot be bound
            # No need for an error message, we will already let the user know
            # that the function is not bound.
            return None

        print "Error: XML Node has unknown type\n", self.gir.debug(node)
        return None

    def _properties(self):
        n = QName(uri, "property")

        props = list(self.node.findall(n.text))
        if props:
            adaprops = []
            section = self.pkg.section("Properties")
            section.add_comment(
                """The following properties are defined for this widget.
See Glib.Properties for more information on properties)""")

            for p in props:
                flags = []
                if p.get("readable", "1") != "0":
                    flags.append("read")
                if p.get("writable", "1") != "0":
                    flags.append("write")

                type = self._get_type(p).as_ada_param()
                pkg  = "Glib.Properties"

                if type == "UTF8_String":
                    type = "String"
                elif type == "Widget":
                    type = "Object"
                elif type == "gdouble":
                    type = "Double"
                elif type == "gint":
                    type = "Int"
                elif type.startswith("Gtk_"):
                    self.pkg.add_with("Gtk.Enums")
                    pkg = "Gtk.Enums"

                adaprops.append({
                    "cname": p.get("name"),
                    "name": AdaNaming.case(p.get("name")) + "_Property",
                    "flags": "-".join(flags),
                    "doc": p.findtext(ndoc, ""),
                    "pkg": pkg,
                    "type":  type})

            adaprops.sort(lambda x,y: x["name"] <> y["name"])

            for p in adaprops:
                section.add_comment("")
                section.add_comment("Name:  %(name)s" % p)
                section.add_comment("Type:  %(type)s" % p)
                section.add_comment("Flags: %(flags)s" % p)
                if p["doc"]:
                    section.add_comment("%s\n" % p["doc"])

            self.pkg.add_with("Glib.Properties")

            for p in adaprops:
                d = '   %(name)s : constant %(pkg)s.Property_%(type)s' % p
                section.add (d + ";")
                self.pkg.add_private(
                    d + ':=\n     %(pkg)s.Build ("%(name)s");' % p)

    def _signals(self):
        signals = list(self.node.findall(gsignal))
        if signals:
            adasignals = []
            section = self.pkg.section("Signals")
            section.add_comment(
                "The following new signals are defined for this widget:")

            for s in signals:
                sub = Subprogram(
                    name="Handler",
                    plist=[
                      Parameter(
                          name="Self",
                          type="%(ns)s_%(name)s_Record'Class" % self._subst,
                          mode="access",
                          doc="")],
                    code="null",
                    returns=s.find(nreturn).find(ntype).get("name"))
                adasignals.append({
                    "name": s.get("name"),
                    "profile": fill_text(sub.spec(), "   --      ", 79, 69),
                    "doc": s.findtext(ndoc, "")})

            adasignals.sort(lambda x,y: x["name"] <> y["name"])

            for s in adasignals:
                section.add_comment("")
                section.add_comment('"%(name)s"' % s)
                section.add_comment(" %(profile)s""" % s)
                if s["doc"]:
                    section.add_comment("  %s""" % s["doc"])

            for s in adasignals:
                section.add(
                    '   Signal_%s : constant Glib.Signal_Name := "%s";' % (
                    AdaNaming.case(s["name"]), s["name"]))

    def generate(self, gir):
        name = "%(ns)s.%(name)s" % self._subst

        self.gtkpkg = gtkada.get_pkg(name)

        self.pkg = gir.get_package(self.gtkpkg.into() or name)
        self.pkg.add_with("%(ns)s.%(parent)s" % self._subst)

        type_name = "%(ns)s_%(name)s" % self._subst
        self._subst["typename"] = type_name
        gtktype = self.gtkpkg.get_type(type_name)

        section = self.pkg.section("")

        if gtktype.is_subtype():
            section.add(
            """
subtype %(typename)s_Record is %(ns)s_%(parent)s_Record;
subtype %(typename)s is %(ns)s_%(parent)s;""" % self._subst);

        else:
            section.add(
            """
type %(typename)s_Record is new %(ns)s_%(parent)s_Record with null record;
type %(typename)s is access all %(typename)s_Record'Class;"""
            % self._subst)

        self._constructors()
        self._method_get_type()
        self._methods()
        self._properties()
        self._signals()

Package.copyright_header="""-----------------------------------------------------------------------
--               GtkAda - Ada95 binding for Gtk+/Gnome               --
--                                                                   --
--   Copyright (C) 1998-2000 E. Briot, J. Brobecker and A. Charlet   --
--                Copyright (C) 2000-2011, AdaCore                   --
--                                                                   --
-- This library is free software; you can redistribute it and/or     --
-- modify it under the terms of the GNU General Public               --
-- License as published by the Free Software Foundation; either      --
-- version 2 of the License, or (at your option) any later version.  --
--                                                                   --
-- This library is distributed in the hope that it will be useful,   --
-- but WITHOUT ANY WARRANTY; without even the implied warranty of    --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU --
-- General Public License for more details.                          --
--                                                                   --
-- You should have received a copy of the GNU General Public         --
-- License along with this library; if not, write to the             --
-- Free Software Foundation, Inc., 59 Temple Place - Suite 330,      --
-- Boston, MA 02111-1307, USA.                                       --
--                                                                   --
-- As a special exception, if other files instantiate generics from  --
-- this unit, or you link this unit with other files to produce an   --
-- executable, this  unit  does not  by itself cause  the resulting  --
-- executable to be covered by the GNU General Public License. This  --
-- exception does not however invalidate any other reasons why the   --
-- executable file  might be covered by the  GNU Public License.     --
-----------------------------------------------------------------------
"""

AdaNaming.exceptions.update({
    "Treeselection": "Tree_Selection",
    "Selectionmode": "Selection_Mode"
})


gir = GIR(sys.argv[1])
gtkada = GtkAda(sys.argv[2])
out = file("generated/tmp.ada", "w")

if False:
    klass = gir.getClass("Frame")
    klass.generate(gir)
else:
    for name, klass in gir.all_classes():
        if name not in ("Widget", "Object", "Container", "Style"):
            print "Generating code for %s" % name
            klass.generate(gir)

gir.generate(out)