/* gtkcolorcombo - color combo widget for gtk+
 * Copyright 1999-2001  Adrian E. Feiguin <feiguin@ifir.edu.ar>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */


#ifndef __GTK_COLOR_COMBO_H__
#define __GTK_COLOR_COMBO_H__

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

#include "gtkcombobox.h"

#define GTK_COLOR_COMBO(obj)			GTK_CHECK_CAST (obj, gtk_color_combo_get_type (), GtkColorCombo)
#define GTK_COLOR_COMBO_CLASS(klass)	GTK_CHECK_CLASS_CAST (klass, gtk_color_combo_get_type (), GtkColorComboClass)
#define GTK_IS_COLOR_COMBO(obj)       GTK_CHECK_TYPE (obj, gtk_color_combo_get_type ())

typedef struct _GtkColorCombo		GtkColorCombo;
typedef struct _GtkColorComboClass	GtkColorComboClass;

/* you should access only the entry and list fields directly */
struct _GtkColorCombo {
	GtkComboBox color_combo;

        gint default_flag:1;

        gint nrows;
        gint ncols;
        gint row;
        gint column;

        GtkWidget ***button;
	GtkWidget *table;
        GtkWidget *custom_button;

        gchar **color_name;
};

struct _GtkColorComboClass {
	GtkComboBoxClass parent_class;

        void (*changed) (GtkColorCombo *color_combo, 
                         gint selection, gchar *color_name);
};

guint      gtk_color_combo_get_type              (void);

GtkWidget *gtk_color_combo_new                   (void);

GtkWidget *gtk_color_combo_new_with_values       (gint nrows, gint ncols,
                                                  gchar **color_names);
gchar     *gtk_color_combo_get_color_at 	 (GtkColorCombo *combo,
                                                  gint row, gint col);
void      gtk_color_combo_find_color		 (GtkColorCombo *color_combo,
                           			  GdkColor *color, 
						  gint *row, gint *col);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* __GTK_COLOR_COMBO_H__ */


