package fr.inria.hop;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Enumeration;
import java.util.Vector;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;
import java.math.BigInteger;
import java.util.Date;
import java.lang.String;

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.app.AlertDialog;
import android.content.DialogInterface;

import fr.inria.hop.Term;

// shamelessly copied from MonoActivity
// http://github.com/koush/androidmono/blob/master/MonoActivity/src/com/koushikdutta/mono/MonoActivity.java

public class hop extends Activity {
   static Runtime mRuntime = Runtime.getRuntime();
   final static String mAppRoot = "/data/data/fr.inria.hop";
   final static int BUFSIZE = 10*1024; // 10k
   final static String APK_PATH = "/data/app/fr.inria.hop.apk";
   final static String assetsFilter = "assets";
   final static String librarySuffix = ".so";
   final static String libraryInitSuffix = ".init";
   final static String dot_afile = "dot.afile";
   final static File wizard_hop= new File (mAppRoot+"/home/.config/hop/wizard.hop");

   public static void Log(String string) {
      Log.v("hop-installer", string);
      // mStatus.append(string+"\n");
   }

   public static void copyStreams(InputStream is, FileOutputStream fos) {
      BufferedOutputStream os = null;
      try {
         byte data[] = new byte[BUFSIZE];
         int count;
         os = new BufferedOutputStream(fos, BUFSIZE);
         while ((count = is.read(data, 0, BUFSIZE)) != -1) {
               os.write(data, 0, count);
         }
         os.flush();
      } catch (IOException e) {
         Log("Exception while copying: " + e);
      } finally {
         try {
               if (os != null) {
                  os.close();
               }
         } catch (IOException e2) {
               Log("Exception while closing the stream: " + e2);
         }
      }
   }

   public static void unpack() {
      File zipFile = new File(APK_PATH);
      long zipLastModified = zipFile.lastModified();
      try {
         ZipFile zip = new ZipFile(APK_PATH);

         Vector<ZipEntry> files = filesFromZip(zip);
         int zipFilterLength = assetsFilter.length();

         Enumeration entries = files.elements();
         while (entries.hasMoreElements()) {
            ZipEntry entry = (ZipEntry) entries.nextElement();
            String path = entry.getName().substring(zipFilterLength);
            // convert dot.afile into .afile
            if (path.endsWith (dot_afile)) {
               path = path.replace (dot_afile, ".afile");
               Log(".afile: "+path);
            }
            if (path.endsWith ("hoprc.hop")) {
               path = path.replace ("config", ".config");
               Log(".config: "+path);
            }
            File outputFile = new File(mAppRoot, path);
            File parent = outputFile.getParentFile();
            parent.mkdirs();
            if (outputFile.exists() && entry.getSize() == outputFile.length() &&
                  zipLastModified < outputFile.lastModified()) {
               Log(outputFile.getName() + " already extracted and not older.");
            } else {
               try {
                  FileOutputStream fos = new FileOutputStream(outputFile);
                  Log(path+" installed...");
                  copyStreams(zip.getInputStream(entry), fos);
                  String curPath = outputFile.getAbsolutePath();
                  do {
                        mRuntime.exec("/system/bin/chmod 755 " + curPath);
                        curPath = new File(curPath).getParent();
                  } while (!curPath.equals(mAppRoot));
               } catch (IOException e) {
                  Log("Error: " + e.toString());
               }
            }
         }
      } catch (IOException e) {
         Log("Error: " + e.toString());
      }

   }

   public static Vector<ZipEntry> filesFromZip(ZipFile zip) {
      // we don't copy the whole contents of the .apk file
      // just what is filtered with this function
      Vector<ZipEntry> list= new Vector<ZipEntry>();
      Enumeration entries= zip.entries();
      while (entries.hasMoreElements()) {
         ZipEntry entry= (ZipEntry) entries.nextElement();
         String name= entry.getName();
         if (name.startsWith (assetsFilter)) {
               list.add(entry);
         } else {
               // Log (name + " skipped: not an asset?");
         }
      }
      return list;
   }

   /*
      from weblets/wizard/wizard.hop:
      ~(define (crypt na pd)
         (string-append "+" (digest-password-encrypt na pd (hop-realm))))

      from runtime/password.scm:
      (define (digest-password-encrypt n p r)
         (md5sum (string-append n ":" r ":" p)))

      from runtime/param.scm:
      (define-parameter hop-realm
         "hop")
   */
   public static String crypt (String na, String pd) {
      byte[] md5sum= {};
      String ans;

      try {
         java.security.MessageDigest digest= java.security.MessageDigest.getInstance ("MD5");
         md5sum= digest.digest ((na+":hop:"+pd).getBytes());
         ans= "+"+getHex (md5sum);
      } catch (java.security.NoSuchAlgorithmException e) {
         // we really can't do much here
         ans= null;
      }

      return ans;
   }

   public static void write (FileOutputStream fos, String line) throws IOException {
      fos.write (line.getBytes ());
      Log(line);
   }

   public static String createAdminUser () {
      // we create the wizard.hop file with an initial admin user
      // whose password is randomly generated
      String password= null;
      String scrambled= null;

      if (firstTime ()) {
         Log("Creating admin user");
         // 32bits==4bytes==8 hexa digits, 4Gi combinations
         password= new BigInteger (32, new java.util.Random ()).toString (16);
         scrambled= crypt ("admin", password);
         Log("pass:  " + password);
         Log("scram: " + scrambled);

         if (scrambled!=null) {
            try {
               FileOutputStream fos= new FileOutputStream (wizard_hop);
               Date now= new Date ();
               String date= now.toString ();

               write (fos, ";; generated file, Hop installer "+date+"\n");
               write (fos, ";; anonymous user\n");
               write (fos, "(add-user! \"anonymous\")\n");

               write (fos, ";; admin\n");
               write (fos, "(add-user! \"admin\" :groups (quote (admin exec)) :password \""+scrambled+"\" :directories (quote *) :services (quote *))\n");
            } catch (IOException e) {
               Log ("can't write "+wizard_hop.getPath ()+": "+e);
               // if we can't set the password
               password= null;
            }
         } else {
            Log("couldn't generate the scrambled password; maybe there's no md5 algrithm?");
            password= null;
         }
      } else {
         // we're screwed
         try {
            FileInputStream fis= new FileInputStream (wizard_hop);
            byte data[] = new byte[BUFSIZE];
            int count;

            Log("here's the config");
            while ((count = fis.read(data, 0, BUFSIZE)) != -1) {
               String foo= "";
               // Log(String (data));
               for (int i=0; i<count; i++) {
                  foo+= data[i];
               }
               Log(foo);
            }
         } catch (IOException e) {
            // we can't even read the file
            Log ("can't even read "+wizard_hop.getPath ()+": "+e);
         }
      }

      // return the admin password
      return password;
   }

   // copied from http://www.rgagnon.com/javadetails/java-0596.html
   // CC by-nc-sa Réal Gagnon <real@rgagnon.com>
   static final String HEXES = "0123456789abcdef";
   public static String getHex( byte [] raw ) {
      if ( raw == null ) {
         return null;
      }
      final StringBuilder hex = new StringBuilder( 2 * raw.length );
      for ( final byte b : raw ) {
         hex.append(HEXES.charAt((b & 0xF0) >> 4)).append(HEXES.charAt((b & 0x0F)));
      }
      return hex.toString();
   }

   static final boolean firstTime () {
      return ! wizard_hop.exists ();
   }

   static final void init (Term term) {
      // TODO: what on updates?
      if (firstTime ()) {
         unpack ();
         String password= createAdminUser ();

         AlertDialog.Builder builder = new AlertDialog.Builder(term);
         builder.setMessage("Hop has been installed. The admin password is: "+password)
               .setCancelable(false)
               .setPositiveButton("Ok", new DialogInterface.OnClickListener() {
                  public void onClick(DialogInterface dialog, int id) {
                     dialog.dismiss();
                  }
               });
         AlertDialog alert = builder.create();
         alert.show ();
      } else {
         Log("not the first time!");
      }
   }
}